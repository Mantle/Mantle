//
//  MTLEXTRuntimeExtensions.h
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-03-05.
//  Copyright (C) 2012 Justin Spahr-Summers.
//  Released under the MIT license.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>

/**
 * A callback indicating that the given method failed to be added to the given
 * class. The reason for the failure depends on the attempted task.
 */
typedef void (*mtl_failedMethodCallback)(Class, Method);

/**
 * Used with #mtl_injectMethods to determine injection behavior.
 */
typedef NS_OPTIONS(NSUInteger, mtl_methodInjectionBehavior) {
    /**
     * Indicates that any existing methods on the destination class should be
     * overwritten.
     */
    mtl_methodInjectionReplace                  = 0x00,

    /**
     * Avoid overwriting methods on the immediate destination class.
     */
    mtl_methodInjectionFailOnExisting           = 0x01,

    /**
     * Avoid overriding methods implemented in any superclass of the destination
     * class.
     */
    mtl_methodInjectionFailOnSuperclassExisting = 0x02,

    /**
     * Avoid overwriting methods implemented in the immediate destination class
     * or any superclass. This is equivalent to
     * <tt>mtl_methodInjectionFailOnExisting | mtl_methodInjectionFailOnSuperclassExisting</tt>.
     */
    mtl_methodInjectionFailOnAnyExisting        = 0x03,

    /**
     * Ignore the \c +load class method. This does not affect instance method
     * injection.
     */
    mtl_methodInjectionIgnoreLoad = 1U << 2,

    /**
     * Ignore the \c +initialize class method. This does not affect instance method
     * injection.
     */
    mtl_methodInjectionIgnoreInitialize = 1U << 3
};

/**
 * A mask for the overwriting behavior flags of #mtl_methodInjectionBehavior.
 */
static const mtl_methodInjectionBehavior mtl_methodInjectionOverwriteBehaviorMask = 0x3;

/**
 * Describes the memory management policy of a property.
 */
typedef enum {
    /**
     * The value is assigned.
     */
    mtl_propertyMemoryManagementPolicyAssign = 0,

    /**
     * The value is retained.
     */
    mtl_propertyMemoryManagementPolicyRetain,

    /**
     * The value is copied.
     */
    mtl_propertyMemoryManagementPolicyCopy
} mtl_propertyMemoryManagementPolicy;

/**
 * Describes the attributes and type information of a property.
 */
typedef struct {
    /**
     * Whether this property was declared with the \c readonly attribute.
     */
    BOOL readonly;

    /**
     * Whether this property was declared with the \c nonatomic attribute.
     */
    BOOL nonatomic;

    /**
     * Whether the property is a weak reference.
     */
    BOOL weak;

    /**
     * Whether the property is eligible for garbage collection.
     */
    BOOL canBeCollected;

    /**
     * Whether this property is defined with \c \@dynamic.
     */
    BOOL dynamic;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"

    /**
     * The memory management policy for this property. This will always be
     * #mtl_propertyMemoryManagementPolicyAssign if #readonly is \c YES.
     */
    mtl_propertyMemoryManagementPolicy memoryManagementPolicy;


    /**
     * The selector for the getter of this property. This will reflect any
     * custom \c getter= attribute provided in the property declaration, or the
     * inferred getter name otherwise.
     */
    SEL getter;

    /**
     * The selector for the setter of this property. This will reflect any
     * custom \c setter= attribute provided in the property declaration, or the
     * inferred setter name otherwise.
     *
     * @note If #readonly is \c YES, this value will represent what the setter
     * \e would be, if the property were writable.
     */
    SEL setter;

#pragma clang diagnostic pop

    /**
     * The backing instance variable for this property, or \c NULL if \c
     * \c @synthesize was not used, and therefore no instance variable exists. This
     * would also be the case if the property is implemented dynamically.
     */
    const char *ivar;

    /**
     * If this property is defined as being an instance of a specific class,
     * this will be the class object representing it.
     *
     * This will be \c nil if the property was defined as type \c id, if the
     * property is not of an object type, or if the class could not be found at
     * runtime.
     */
    Class objectClass;

    /**
     * The type encoding for the value of this property. This is the type as it
     * would be returned by the \c \@encode() directive.
     */
    char type[];
} mtl_propertyAttributes;

/**
 * Iterates through the first \a count entries in \a methods and attempts to add
 * each one to \a aClass. If a method by the same name already exists on \a
 * aClass, it is \e not overridden. If \a checkSuperclasses is \c YES, and
 * a method by the same name already exists on any superclass of \a aClass, it
 * is not overridden.
 *
 * Returns the number of methods added successfully. For each method that fails
 * to be added, \a failedToAddCallback (if provided) is invoked.
 */
unsigned mtl_addMethods (Class aClass, Method *methods, unsigned count, BOOL checkSuperclasses, mtl_failedMethodCallback failedToAddCallback);

/**
 * Iterates through all instance and class methods of \a srcClass and attempts
 * to add each one to \a dstClass. If a method by the same name already exists
 * on \a aClass, it is \e not overridden. If \a checkSuperclasses is \c YES, and
 * a method by the same name already exists on any superclass of \a aClass, it
 * is not overridden.
 *
 * Returns whether all methods were added successfully. For each method that fails
 * to be added, \a failedToAddCallback (if provided) is invoked.
 *
 * @note This ignores any \c +load method on \a srcClass. \a srcClass and \a
 * dstClass must not be metaclasses.
 */
BOOL mtl_addMethodsFromClass (Class srcClass, Class dstClass, BOOL checkSuperclasses, mtl_failedMethodCallback failedToAddCallback);

/**
 * Returns the superclass of \a receiver which immediately descends from \a
 * superclass. If \a superclass is not in the hierarchy of \a receiver, or is
 * equal to \a receiver, \c nil is returned.
 */
Class mtl_classBeforeSuperclass (Class receiver, Class superclass);

/**
 * Returns whether \a receiver is \a aClass, or inherits directly from it.
 */
BOOL mtl_classIsKindOfClass (Class receiver, Class aClass);

/**
 * Returns the full list of classes registered with the runtime, terminated with
 * \c NULL. If \a count is not \c NULL, it is filled in with the total number of
 * classes returned. You must \c free() the returned array.
 */
Class *mtl_copyClassList (unsigned *count);

/**
 * Looks through the complete list of classes registered with the runtime and
 * finds all classes which conform to \a protocol. Returns \c *count classes
 * terminated by a \c NULL. You must \c free() the returned array. If there are no
 * classes conforming to \a protocol, \c NULL is returned.
 *
 * @note \a count may be \c NULL.
 */
Class *mtl_copyClassListConformingToProtocol (Protocol *protocol, unsigned *count);

/**
 * Returns a pointer to a structure containing information about \a property.
 * You must \c free() the returned pointer. Returns \c NULL if there is an error
 * obtaining information from \a property.
 */
mtl_propertyAttributes *mtl_copyPropertyAttributes (objc_property_t property);

/**
 * Looks through the complete list of classes registered with the runtime and
 * finds all classes which are descendant from \a aClass. Returns \c
 * *subclassCount classes terminated by a \c NULL. You must \c free() the
 * returned array. If there are no subclasses of \a aClass, \c NULL is
 * returned.
 *
 * @note \a subclassCount may be \c NULL. \a aClass may be a metaclass to get
 * all subclass metaclass objects.
 */
Class *mtl_copySubclassList (Class aClass, unsigned *subclassCount);

/**
 * Finds the instance method named \a aSelector on \a aClass and returns it, or
 * returns \c NULL if no such instance method exists. Unlike \c
 * class_getInstanceMethod(), this does not search superclasses.
 *
 * @note To get class methods in this manner, use a metaclass for \a aClass.
 */
Method mtl_getImmediateInstanceMethod (Class aClass, SEL aSelector);

/**
 * Returns the value of \c Ivar \a IVAR from instance \a OBJ. The instance
 * variable must be of type \a TYPE, and is returned as such.
 *
 * @warning Depending on the platform, this may or may not work with aggregate
 * or floating-point types.
 */
#define mtl_getIvar(OBJ, IVAR, TYPE) \
    ((TYPE (*)(id, Ivar)object_getIvar)((OBJ), (IVAR)))

/**
 * Returns the value of the instance variable identified by the string \a NAME
 * from instance \a OBJ. The instance variable must be of type \a TYPE, and is
 * returned as such.
 *
 * @note \a OBJ is evaluated twice.
 *
 * @warning Depending on the platform, this may or may not work with aggregate
 * or floating-point types.
 */
#define mtl_getIvarByName(OBJ, NAME, TYPE) \
    mtl_getIvar((OBJ), class_getInstanceVariable(object_getClass((OBJ)), (NAME)), TYPE)

/**
 * Returns the accessor methods for \a property, as implemented in \a aClass or
 * any of its superclasses. The getter, if implemented, is returned in \a
 * getter, and the setter, if implemented, is returned in \a setter. If either
 * \a getter or \a setter are \c NULL, that accessor is not returned. If either
 * accessor is not implemented, the argument is left unmodified.
 *
 * Returns \c YES if a valid accessor was found, or \c NO if \a aClass and its
 * superclasses do not implement \a property or if an error occurs.
 */
BOOL mtl_getPropertyAccessorsForClass (objc_property_t property, Class aClass, Method *getter, Method *setter);

/**
 * For all classes registered with the runtime, invokes \c
 * methodSignatureForSelector: and \c instanceMethodSignatureForSelector: to
 * determine a method signature for \a aSelector. If one or more valid
 * signatures is found, the first one is returned. If no valid signatures were
 * found, \c nil is returned.
 */
NSMethodSignature *mtl_globalMethodSignatureForSelector (SEL aSelector);

/**
 * Highly-configurable method injection. Adds the first \a count entries from \a
 * methods into \a aClass according to \a behavior.
 *
 * Returns the number of methods added successfully. For each method that fails
 * to be added, \a failedToAddCallback (if provided) is invoked.
 *
 * @note \c +load and \c +initialize methods are included in the number of
 * successful methods when ignored for injection.
 */
unsigned mtl_injectMethods (Class aClass, Method *methods, unsigned count, mtl_methodInjectionBehavior behavior, mtl_failedMethodCallback failedToAddCallback);

/**
 * Invokes #mtl_injectMethods with the instance methods and class methods from
 * \a srcClass. #mtl_methodInjectionIgnoreLoad is added to #behavior for class
 * method injection.
 *
 * Returns whether all methods were added successfully. For each method that fails
 * to be added, \a failedToAddCallback (if provided) is invoked.
 *
 * @note \c +load and \c +initialize methods are considered to be added
 * successfully when ignored for injection.
 */
BOOL mtl_injectMethodsFromClass (Class srcClass, Class dstClass, mtl_methodInjectionBehavior behavior, mtl_failedMethodCallback failedToAddCallback);

/**
 * Loads a "special protocol" into an internal list. A special protocol is any
 * protocol for which implementing classes need injection behavior (i.e., any
 * class conforming to the protocol needs to be reflected upon). Returns \c NO
 * if loading failed.
 *
 * Using this facility proceeds as follows:
 *
 * @li Each protocol is loaded with #mtl_loadSpecialProtocol and a custom block
 * that describes its injection behavior on each conforming class.
 * @li Each protocol is marked as being ready for injection with
 * #mtl_specialProtocolReadyForInjection.
 * @li The entire Objective-C class list is retrieved, and each special
 * protocol's \a injectionBehavior block is run for all conforming classes.
 *
 * It is an error to call this function without later calling
 * #mtl_specialProtocolReadyForInjection as well.
 *
 * @note A special protocol X which conforms to another special protocol Y is
 * always injected \e after Y.
 */
BOOL mtl_loadSpecialProtocol (Protocol *protocol, void (^injectionBehavior)(Class destinationClass));

/**
 * Marks a special protocol as being ready for injection. Injection is actually
 * performed only after all special protocols have been marked in this way.
 *
 * @sa mtl_loadSpecialProtocol
 */
void mtl_specialProtocolReadyForInjection (Protocol *protocol);

/**
 * Creates a human-readable description of the data in \a bytes, interpreting it
 * according to the given Objective-C type encoding.
 *
 * This is intended for use with debugging, and code should not depend upon the
 * format of the returned string (just like a call to \c -description).
 */
NSString *mtl_stringFromTypedBytes (const void *bytes, const char *encoding);

/**
 * "Removes" any instance method matching \a methodName from \a aClass. This
 * removal can mean one of two things:
 *
 * @li If any superclass of \a aClass implements a method by the same name, the
 * implementation of the closest such superclass is used.
 * @li If no superclasses of \a aClass implement a method by the same name, the
 * method is replaced with an implementation internal to the runtime, used for
 * message forwarding.
 *
 * @warning Adding a method by the same name into a superclass of \a aClass \e
 * after using this function may obscure it from the subclass.
 */
void mtl_removeMethod (Class aClass, SEL methodName);

/**
 * Iterates through the first \a count entries in \a methods and adds each one
 * to \a aClass, replacing any existing implementation.
 */
void mtl_replaceMethods (Class aClass, Method *methods, unsigned count);

/**
 * Iterates through all instance and class methods of \a srcClass and adds each
 * one to \a dstClass, replacing any existing implementation.
 *
 * @note This ignores any \c +load method on \a srcClass. \a srcClass and \a
 * dstClass must not be metaclasses.
 */
void mtl_replaceMethodsFromClass (Class srcClass, Class dstClass);

