//
//  MTLEXTRuntimeExtensions.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-05.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import "MTLEXTRuntimeExtensions.h"
#import <ctype.h>
#import <libkern/OSAtomic.h>
#import <objc/message.h>
#import <os/lock.h>
#import <pthread.h>
#import <stdio.h>
#import <stdlib.h>
#import <string.h>

typedef NSMethodSignature *(*methodSignatureForSelectorIMP)(id, SEL, SEL);
typedef void (^mtl_specialProtocolInjectionBlock)(Class);

// a `const char *` equivalent to system struct objc_method_description
typedef struct {
    SEL name;
    const char *types;
} mtl_methodDescription;

// contains the information needed to reference a full special protocol
typedef struct {
    // the actual protocol declaration (@protocol block)
    __unsafe_unretained Protocol *protocol;

    // the injection block associated with this protocol
    //
    // this block is RETAINED and must eventually be released by transferring it
    // back to ARC
    void *injectionBlock;

    // whether this protocol is ready to be injected to its conforming classes
    //
    // this does NOT refer to a special protocol having been injected already
    BOOL ready;
} MTLSpecialProtocol;

// the full list of special protocols (an array of MTLSpecialProtocol structs)
static MTLSpecialProtocol * restrict specialProtocols = NULL;

// the number of special protocols stored in the array
static size_t specialProtocolCount = 0;

// the total capacity of the array
// we use a doubling algorithm to amortize the cost of insertion, so this is
// generally going to be a power-of-two
static size_t specialProtocolCapacity = 0;

// the number of MTLSpecialProtocols which have been marked as ready for
// injection (though not necessary injected)
//
// in other words, the total count which have 'ready' set to YES
static size_t specialProtocolsReady = 0;

// a mutex is used to guard against multiple threads changing the above static
// variables
static pthread_mutex_t specialProtocolsLock = PTHREAD_MUTEX_INITIALIZER;

/**
 * This function actually performs the hard work of special protocol injection.
 * It obtains a full list of all classes registered with the Objective-C
 * runtime, finds those conforming to special protocols, and then runs the
 * injection blocks as appropriate.
 */
static void mtl_injectSpecialProtocols (void) {
    /*
     * don't lock specialProtocolsLock in this function, as it is called only
     * from public functions which already perform the synchronization
     */

    /*
     * This will sort special protocols in the order they should be loaded. If
     * a special protocol conforms to another special protocol, the former
     * will be prioritized above the latter.
     */
    qsort_b(specialProtocols, specialProtocolCount, sizeof(MTLSpecialProtocol), ^(const void *a, const void *b){
        // if the pointers are equal, it must be the same protocol
        if (a == b)
            return 0;

        const MTLSpecialProtocol *protoA = a;
        const MTLSpecialProtocol *protoB = b;

        // A higher return value here means a higher priority
        int (^protocolInjectionPriority)(const MTLSpecialProtocol *) = ^(const MTLSpecialProtocol *specialProtocol){
            int runningTotal = 0;

            for (size_t i = 0;i < specialProtocolCount;++i) {
                // the pointer passed into this block is guaranteed to point
                // into the 'specialProtocols' array, so we can compare the
                // pointers directly for identity
                if (specialProtocol == specialProtocols + i)
                    continue;

                if (protocol_conformsToProtocol(specialProtocol->protocol, specialProtocols[i].protocol))
                    runningTotal++;
            }

            return runningTotal;
        };

        /*
         * This will return:
         * 0 if the protocols are equal in priority (such that load order does not matter)
         * < 0 if A is more important than B
         * > 0 if B is more important than A
         */
        return protocolInjectionPriority(protoB) - protocolInjectionPriority(protoA);
    });

    unsigned classCount = objc_getClassList(NULL, 0);
    if (!classCount) {
        fprintf(stderr, "ERROR: No classes registered with the runtime\n");
        return;
    }

	Class *allClasses = (Class *)malloc(sizeof(Class) * (classCount + 1));
    if (!allClasses) {
        fprintf(stderr, "ERROR: Could not allocate space for %u classes\n", classCount);
        return;
    }

	// use this instead of mtl_copyClassList() to avoid sending +initialize to
	// classes that we don't plan to inject into (this avoids some SenTestingKit
	// timing issues)
	classCount = objc_getClassList(allClasses, classCount);

    /*
     * set up an autorelease pool in case any Cocoa classes get used during
     * the injection process or +initialize
     */
    @autoreleasepool {
        // loop through the special protocols, and apply each one to all the
        // classes in turn
        //
        // ORDER IS IMPORTANT HERE: protocols have to be injected to all classes in
        // the order in which they appear in specialProtocols. Consider classes
        // X and Y that implement protocols A and B, respectively. B needs to get
        // its implementation into Y before A gets into X.
        for (size_t i = 0;i < specialProtocolCount;++i) {
            Protocol *protocol = specialProtocols[i].protocol;

            // transfer ownership of the injection block to ARC and remove it
            // from the structure
            mtl_specialProtocolInjectionBlock injectionBlock = (__bridge_transfer id)specialProtocols[i].injectionBlock;
            specialProtocols[i].injectionBlock = NULL;

            // loop through all classes
            for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
                Class class = allClasses[classIndex];

                // if this class doesn't conform to the protocol, continue to the
                // next class immediately
                if (!class_conformsToProtocol(class, protocol))
                    continue;

                injectionBlock(class);
            }
        }
    }

    // free the allocated class list
    free(allClasses);

    // now that everything's injected, the special protocol list can also be
    // destroyed
    free(specialProtocols); specialProtocols = NULL;
    specialProtocolCount = 0;
    specialProtocolCapacity = 0;
    specialProtocolsReady = 0;
}

unsigned mtl_injectMethods (
    Class aClass,
    Method *methods,
    unsigned count,
    mtl_methodInjectionBehavior behavior,
    mtl_failedMethodCallback failedToAddCallback
) {
    unsigned successes = 0;

    /*
     * set up an autorelease pool in case any Cocoa classes invoke +initialize
     * during this process
     */
    @autoreleasepool {
        BOOL isMeta = class_isMetaClass(aClass);

        if (!isMeta) {
            // clear any +load and +initialize ignore flags
            behavior &= ~(mtl_methodInjectionIgnoreLoad | mtl_methodInjectionIgnoreInitialize);
        }

        for (unsigned methodIndex = 0;methodIndex < count;++methodIndex) {
            Method method = methods[methodIndex];
            SEL methodName = method_getName(method);

            if (behavior & mtl_methodInjectionIgnoreLoad) {
                if (methodName == @selector(load)) {
                    ++successes;
                    continue;
                }
            }

            if (behavior & mtl_methodInjectionIgnoreInitialize) {
                if (methodName == @selector(initialize)) {
                    ++successes;
                    continue;
                }
            }

            BOOL success = YES;
            IMP impl = method_getImplementation(method);
            const char *type = method_getTypeEncoding(method);

            switch (behavior & mtl_methodInjectionOverwriteBehaviorMask) {
            case mtl_methodInjectionFailOnExisting:
                success = class_addMethod(aClass, methodName, impl, type);
                break;

            case mtl_methodInjectionFailOnAnyExisting:
                if (class_getInstanceMethod(aClass, methodName)) {
                    success = NO;
                    break;
                }

                // else fall through

            case mtl_methodInjectionReplace:
                class_replaceMethod(aClass, methodName, impl, type);
                break;

            case mtl_methodInjectionFailOnSuperclassExisting:
                {
                    Class superclass = class_getSuperclass(aClass);
                    if (superclass && class_getInstanceMethod(superclass, methodName))
                        success = NO;
                    else
                        class_replaceMethod(aClass, methodName, impl, type);
                }

                break;

            default:
                fprintf(stderr, "ERROR: Unrecognized method injection behavior: %i\n", (int)(behavior & mtl_methodInjectionOverwriteBehaviorMask));
            }

            if (success)
                ++successes;
            else
                failedToAddCallback(aClass, method);
        }
    }

    return successes;
}

BOOL mtl_injectMethodsFromClass (
    Class srcClass,
    Class dstClass,
    mtl_methodInjectionBehavior behavior,
    mtl_failedMethodCallback failedToAddCallback)
{
    unsigned count, addedCount;
    BOOL success = YES;

    count = 0;
    Method *instanceMethods = class_copyMethodList(srcClass, &count);

    addedCount = mtl_injectMethods(
        dstClass,
        instanceMethods,
        count,
        behavior,
        failedToAddCallback
    );

    free(instanceMethods);
    if (addedCount < count)
        success = NO;

    count = 0;
    Method *classMethods = class_copyMethodList(object_getClass(srcClass), &count);

    // ignore +load
    behavior |= mtl_methodInjectionIgnoreLoad;
    addedCount = mtl_injectMethods(
        object_getClass(dstClass),
        classMethods,
        count,
        behavior,
        failedToAddCallback
    );

    free(classMethods);
    if (addedCount < count)
        success = NO;

    return success;
}

Class mtl_classBeforeSuperclass (Class receiver, Class superclass) {
    Class previousClass = nil;

    while (![receiver isEqual:superclass]) {
        previousClass = receiver;
        receiver = class_getSuperclass(receiver);
    }

    return previousClass;
}

Class *mtl_copyClassList (unsigned *count) {
    // get the number of classes registered with the runtime
    int classCount = objc_getClassList(NULL, 0);
    if (!classCount) {
        if (count)
            *count = 0;

        return NULL;
    }

    // allocate space for them plus NULL
    Class *allClasses = (Class *)malloc(sizeof(Class) * (classCount + 1));
    if (!allClasses) {
        fprintf(stderr, "ERROR: Could allocate memory for all classes\n");
        if (count)
            *count = 0;

        return NULL;
    }

    // and then actually pull the list of the class objects
    classCount = objc_getClassList(allClasses, classCount);
    allClasses[classCount] = NULL;

    @autoreleasepool {
        // weed out classes that do weird things when reflected upon
        for (int i = 0;i < classCount;) {
            Class class = allClasses[i];
            BOOL keep = YES;

            if (keep)
                keep &= class_respondsToSelector(class, @selector(methodSignatureForSelector:));

            if (keep) {
                if (class_respondsToSelector(class, @selector(isProxy)))
                    keep &= ![class isProxy];
            }

            if (!keep) {
                if (--classCount > i) {
                    memmove(allClasses + i, allClasses + i + 1, (classCount - i) * sizeof(*allClasses));
                }

                continue;
            }

            ++i;
        }
    }

    if (count)
        *count = (unsigned)classCount;

    return allClasses;
}

unsigned mtl_addMethods (Class aClass, Method *methods, unsigned count, BOOL checkSuperclasses, mtl_failedMethodCallback failedToAddCallback) {
    mtl_methodInjectionBehavior behavior = mtl_methodInjectionFailOnExisting;
    if (checkSuperclasses)
        behavior |= mtl_methodInjectionFailOnSuperclassExisting;

    return mtl_injectMethods(
        aClass,
        methods,
        count,
        behavior,
        failedToAddCallback
    );
}

BOOL mtl_addMethodsFromClass (Class srcClass, Class dstClass, BOOL checkSuperclasses, mtl_failedMethodCallback failedToAddCallback) {
    mtl_methodInjectionBehavior behavior = mtl_methodInjectionFailOnExisting;
    if (checkSuperclasses)
        behavior |= mtl_methodInjectionFailOnSuperclassExisting;

    return mtl_injectMethodsFromClass(srcClass, dstClass, behavior, failedToAddCallback);
}

BOOL mtl_classIsKindOfClass (Class receiver, Class aClass) {
    while (receiver) {
        if (receiver == aClass)
            return YES;

        receiver = class_getSuperclass(receiver);
    }

    return NO;
}

Class *mtl_copyClassListConformingToProtocol (Protocol *protocol, unsigned *count) {
    Class *allClasses;

    /*
     * set up an autorelease pool in case any Cocoa classes invoke +initialize
     * during this process
     */
    @autoreleasepool {
        unsigned classCount = 0;
        allClasses = mtl_copyClassList(&classCount);

        if (!allClasses)
            return NULL;

        // we're going to reuse allClasses for the return value, so returnIndex will
        // keep track of the indices we replace with new values
        unsigned returnIndex = 0;

        for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
            Class cls = allClasses[classIndex];
            if (class_conformsToProtocol(cls, protocol))
                allClasses[returnIndex++] = cls;
        }

        allClasses[returnIndex] = NULL;
        if (count)
            *count = returnIndex;
    }

    return allClasses;
}

mtl_propertyAttributes *mtl_copyPropertyAttributes (objc_property_t property) {
    const char * const attrString = property_getAttributes(property);
    if (!attrString) {
        fprintf(stderr, "ERROR: Could not get attribute string from property %s\n", property_getName(property));
        return NULL;
    }

    if (attrString[0] != 'T') {
        fprintf(stderr, "ERROR: Expected attribute string \"%s\" for property %s to start with 'T'\n", attrString, property_getName(property));
        return NULL;
    }

    const char *typeString = attrString + 1;
    const char *next = NSGetSizeAndAlignment(typeString, NULL, NULL);
    if (!next) {
        fprintf(stderr, "ERROR: Could not read past type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }

    size_t typeLength = next - typeString;
    if (!typeLength) {
        fprintf(stderr, "ERROR: Invalid type in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }

    // allocate enough space for the structure and the type string (plus a NUL)
    mtl_propertyAttributes *attributes = calloc(1, sizeof(mtl_propertyAttributes) + typeLength + 1);
    if (!attributes) {
        fprintf(stderr, "ERROR: Could not allocate mtl_propertyAttributes structure for attribute string \"%s\" for property %s\n", attrString, property_getName(property));
        return NULL;
    }

    // copy the type string
    strncpy(attributes->type, typeString, typeLength);
    attributes->type[typeLength] = '\0';

    // if this is an object type, and immediately followed by a quoted string...
    if (typeString[0] == *(@encode(id)) && typeString[1] == '"') {
        // we should be able to extract a class name
        const char *className = typeString + 2;
        next = strchr(className, '"');

        if (!next) {
            fprintf(stderr, "ERROR: Could not read class name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
            goto errorOut;
        }

        if (className != next) {
            size_t classNameLength = next - className;
            char trimmedName[classNameLength + 1];

            strncpy(trimmedName, className, classNameLength);
            trimmedName[classNameLength] = '\0';

            // attempt to look up the class in the runtime
            attributes->objectClass = objc_getClass(trimmedName);
        }
    }

    if (*next != '\0') {
        // skip past any junk before the first flag
        next = strchr(next, ',');
    }

    while (next && *next == ',') {
        char flag = next[1];
        next += 2;

        switch (flag) {
        case '\0':
            break;

        case 'R':
            attributes->readonly = YES;
            break;

        case 'C':
            attributes->memoryManagementPolicy = mtl_propertyMemoryManagementPolicyCopy;
            break;

        case '&':
            attributes->memoryManagementPolicy = mtl_propertyMemoryManagementPolicyRetain;
            break;

        case 'N':
            attributes->nonatomic = YES;
            break;

        case 'G':
        case 'S':
            {
                const char *nextFlag = strchr(next, ',');
                SEL name = NULL;

                if (!nextFlag) {
                    // assume that the rest of the string is the selector
                    const char *selectorString = next;
                    next = "";

                    name = sel_registerName(selectorString);
                } else {
                    size_t selectorLength = nextFlag - next;
                    if (!selectorLength) {
                        fprintf(stderr, "ERROR: Found zero length selector name in attribute string \"%s\" for property %s\n", attrString, property_getName(property));
                        goto errorOut;
                    }

                    char selectorString[selectorLength + 1];

                    strncpy(selectorString, next, selectorLength);
                    selectorString[selectorLength] = '\0';

                    name = sel_registerName(selectorString);
                    next = nextFlag;
                }

                if (flag == 'G')
                    attributes->getter = name;
                else
                    attributes->setter = name;
            }

            break;

        case 'D':
            attributes->dynamic = YES;
            attributes->ivar = NULL;
            break;

        case 'V':
            // assume that the rest of the string (if present) is the ivar name
            if (*next == '\0') {
                // if there's nothing there, let's assume this is dynamic
                attributes->ivar = NULL;
            } else {
                attributes->ivar = next;
                next = "";
            }

            break;

        case 'W':
            attributes->weak = YES;
            break;

        case 'P':
            attributes->canBeCollected = YES;
            break;

        case 't':
            fprintf(stderr, "ERROR: Old-style type encoding is unsupported in attribute string \"%s\" for property %s\n", attrString, property_getName(property));

            // skip over this type encoding
            while (*next != ',' && *next != '\0')
                ++next;

            break;

        default:
            fprintf(stderr, "ERROR: Unrecognized attribute string flag '%c' in attribute string \"%s\" for property %s\n", flag, attrString, property_getName(property));
        }
    }

    if (next && *next != '\0') {
        fprintf(stderr, "Warning: Unparsed data \"%s\" in attribute string \"%s\" for property %s\n", next, attrString, property_getName(property));
    }

    if (!attributes->getter) {
        // use the property name as the getter by default
        attributes->getter = sel_registerName(property_getName(property));
    }

    if (!attributes->setter) {
        const char *propertyName = property_getName(property);
        size_t propertyNameLength = strlen(propertyName);

        // we want to transform the name to setProperty: style
        size_t setterLength = propertyNameLength + 4;

        char setterName[setterLength + 1];
        strncpy(setterName, "set", 3);
        strncpy(setterName + 3, propertyName, propertyNameLength);

        // capitalize property name for the setter
        setterName[3] = (char)toupper(setterName[3]);

        setterName[setterLength - 1] = ':';
        setterName[setterLength] = '\0';

        attributes->setter = sel_registerName(setterName);
    }

    return attributes;

errorOut:
    free(attributes);
    return NULL;
}

Class *mtl_copySubclassList (Class targetClass, unsigned *subclassCount) {
    unsigned classCount = 0;
    Class *allClasses = mtl_copyClassList(&classCount);
    if (!allClasses || !classCount) {
        fprintf(stderr, "ERROR: No classes registered with the runtime, cannot find %s!\n", class_getName(targetClass));
        return NULL;
    }

    // we're going to reuse allClasses for the return value, so returnIndex will
    // keep track of the indices we replace with new values
    unsigned returnIndex = 0;

    BOOL isMeta = class_isMetaClass(targetClass);

    for (unsigned classIndex = 0;classIndex < classCount;++classIndex) {
        Class cls = allClasses[classIndex];
        Class superclass = class_getSuperclass(cls);

        while (superclass != NULL) {
            if (isMeta) {
                if (object_getClass(superclass) == targetClass)
                    break;
            } else if (superclass == targetClass)
                break;

            superclass = class_getSuperclass(superclass);
        }

        if (!superclass)
            continue;

        // at this point, 'cls' is definitively a subclass of targetClass
        if (isMeta)
            cls = object_getClass(cls);

        allClasses[returnIndex++] = cls;
    }

    allClasses[returnIndex] = NULL;
    if (subclassCount)
        *subclassCount = returnIndex;

    return allClasses;
}

Method mtl_getImmediateInstanceMethod (Class aClass, SEL aSelector) {
    unsigned methodCount = 0;
    Method *methods = class_copyMethodList(aClass, &methodCount);
    Method foundMethod = NULL;

    for (unsigned methodIndex = 0;methodIndex < methodCount;++methodIndex) {
        if (method_getName(methods[methodIndex]) == aSelector) {
            foundMethod = methods[methodIndex];
            break;
        }
    }

    free(methods);
    return foundMethod;
}

BOOL mtl_getPropertyAccessorsForClass (objc_property_t property, Class aClass, Method *getter, Method *setter) {
    mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
    if (!attributes)
        return NO;

    SEL getterName = attributes->getter;
    SEL setterName = attributes->setter;

    free(attributes);
    attributes = NULL;

    /*
     * set up an autorelease pool in case this sends aClass its first message
     */
    @autoreleasepool {
        Method foundGetter = class_getInstanceMethod(aClass, getterName);
        if (!foundGetter) {
            return NO;
        }

        if (getter)
            *getter = foundGetter;

        if (setter) {
            Method foundSetter = class_getInstanceMethod(aClass, setterName);
            if (foundSetter)
                *setter = foundSetter;
        }
    }

    return YES;
}

BOOL mtl_loadSpecialProtocol (Protocol *protocol, void (^injectionBehavior)(Class destinationClass)) {
    @autoreleasepool {
        NSCParameterAssert(protocol != nil);
        NSCParameterAssert(injectionBehavior != nil);

        // lock the mutex to prevent accesses from other threads while we perform
        // this work
        if (pthread_mutex_lock(&specialProtocolsLock) != 0) {
            fprintf(stderr, "ERROR: Could not synchronize on special protocol data\n");
            return NO;
        }

        // if we've hit the hard maximum for number of special protocols, we can't
        // continue
        if (specialProtocolCount == SIZE_MAX) {
            pthread_mutex_unlock(&specialProtocolsLock);
            return NO;
        }

        // if the array has no more space, we will need to allocate additional
        // entries
        if (specialProtocolCount >= specialProtocolCapacity) {
            size_t newCapacity;
            if (specialProtocolCapacity == 0)
                // if there are no entries, make space for just one
                newCapacity = 1;
            else {
                // otherwise, double the current capacity
                newCapacity = specialProtocolCapacity << 1;

                // if the new capacity is less than the current capacity, that's
                // unsigned integer overflow
                if (newCapacity < specialProtocolCapacity) {
                    // set it to the maximum possible instead
                    newCapacity = SIZE_MAX;

                    // if the new capacity is still not greater than the current
                    // (for instance, if it was already SIZE_MAX), we can't continue
                    if (newCapacity <= specialProtocolCapacity) {
                        pthread_mutex_unlock(&specialProtocolsLock);
                        return NO;
                    }
                }
            }

            // we have a new capacity, so resize the list of all special protocols
            // to add the new entries
            void * restrict ptr = realloc(specialProtocols, sizeof(*specialProtocols) * newCapacity);
            if (!ptr) {
                // the allocation failed, abort
                pthread_mutex_unlock(&specialProtocolsLock);
                return NO;
            }

            specialProtocols = ptr;
            specialProtocolCapacity = newCapacity;
        }

        // at this point, there absolutely must be at least one empty entry in the
        // array
        assert(specialProtocolCount < specialProtocolCapacity);

        // disable warning about "leaking" this block, which is released in
        // mtl_injectSpecialProtocols()
        #ifndef __clang_analyzer__
        mtl_specialProtocolInjectionBlock copiedBlock = [injectionBehavior copy];

        // construct a new MTLSpecialProtocol structure and add it to the first
        // empty space in the array
        specialProtocols[specialProtocolCount] = (MTLSpecialProtocol){
            .protocol = protocol,
            .injectionBlock = (__bridge_retained void *)copiedBlock,
            .ready = NO
        };
        #endif

        ++specialProtocolCount;
        pthread_mutex_unlock(&specialProtocolsLock);
    }

    // success!
    return YES;
}

void mtl_specialProtocolReadyForInjection (Protocol *protocol) {
    @autoreleasepool {
        NSCParameterAssert(protocol != nil);

        // lock the mutex to prevent accesses from other threads while we perform
        // this work
        if (pthread_mutex_lock(&specialProtocolsLock) != 0) {
            fprintf(stderr, "ERROR: Could not synchronize on special protocol data\n");
            return;
        }

        // loop through all the special protocols in our list, trying to find the
        // one associated with 'protocol'
        for (size_t i = 0;i < specialProtocolCount;++i) {
            if (specialProtocols[i].protocol == protocol) {
                // found the matching special protocol, check to see if it's
                // already ready
                if (!specialProtocols[i].ready) {
                    // if it's not, mark it as being ready now
                    specialProtocols[i].ready = YES;

                    // since this special protocol was in our array, and it was not
                    // loaded, the total number of protocols loaded must be less
                    // than the total count at this point in time
                    assert(specialProtocolsReady < specialProtocolCount);

                    // ... and then increment the total number of special protocols
                    // loaded – if it now matches the total count of special
                    // protocols, begin the injection process
                    if (++specialProtocolsReady == specialProtocolCount)
                        mtl_injectSpecialProtocols();
                }

                break;
            }
        }

        pthread_mutex_unlock(&specialProtocolsLock);
    }
}

void mtl_removeMethod (Class aClass, SEL methodName) {
    Method existingMethod = mtl_getImmediateInstanceMethod(aClass, methodName);
    if (!existingMethod) {
        return;
    }

    /*
     * set up an autorelease pool in case any Cocoa classes invoke +initialize
     * during this process
     */
    @autoreleasepool {
        Method superclassMethod = NULL;
        Class superclass = class_getSuperclass(aClass);
        if (superclass)
            superclassMethod = class_getInstanceMethod(superclass, methodName);

        if (superclassMethod) {
            method_setImplementation(existingMethod, method_getImplementation(superclassMethod));
        } else {
            // since we now know that the method doesn't exist on any
            // superclass, get an IMP internal to the runtime for message forwarding
            IMP forward = class_getMethodImplementation(superclass, methodName);

            method_setImplementation(existingMethod, forward);
        }
    }
}

void mtl_replaceMethods (Class aClass, Method *methods, unsigned count) {
    mtl_injectMethods(
        aClass,
        methods,
        count,
        mtl_methodInjectionReplace,
        NULL
    );
}

void mtl_replaceMethodsFromClass (Class srcClass, Class dstClass) {
    mtl_injectMethodsFromClass(srcClass, dstClass, mtl_methodInjectionReplace, NULL);
}

NSString *mtl_stringFromTypedBytes (const void *bytes, const char *encoding) {
    switch (*encoding) {
        case 'c': return @(*(char *)bytes).description;
        case 'C': return @(*(unsigned char *)bytes).description;
        case 'i': return @(*(int *)bytes).description;
        case 'I': return @(*(unsigned int *)bytes).description;
        case 's': return @(*(short *)bytes).description;
        case 'S': return @(*(unsigned short *)bytes).description;
        case 'l': return @(*(long *)bytes).description;
        case 'L': return @(*(unsigned long *)bytes).description;
        case 'q': return @(*(long long *)bytes).description;
        case 'Q': return @(*(unsigned long long *)bytes).description;
        case 'f': return @(*(float *)bytes).description;
        case 'd': return @(*(double *)bytes).description;
        case 'B': return @(*(_Bool *)bytes).description;
        case 'v': return @"(void)";
        case '*': return [NSString stringWithFormat:@"\"%s\"", (char *)bytes];

        case '@':
        case '#': {
            id obj = *(__unsafe_unretained id *)bytes;
            if (obj)
                return [obj description];
            else
                return @"(nil)";
        }

        case '?':
        case '^': {
            const void *ptr = *(const void **)bytes;
            if (ptr)
                return [NSString stringWithFormat:@"%p", ptr];
            else
                return @"(null)";
        }

        default:
            return [[NSValue valueWithBytes:bytes objCType:encoding] description];
    }
}

