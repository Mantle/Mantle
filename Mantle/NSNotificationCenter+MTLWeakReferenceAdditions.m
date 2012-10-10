//
//  NSNotificationCenter+MTLWeakReferenceAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-26.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSNotificationCenter+MTLWeakReferenceAdditions.h"
#import "EXTScope.h"
#import <objc/runtime.h>

// Used as an associated object on weak observers, so we can automatically
// remove them when they're deallocated.
//
// This is used in addition to -- not instead of -- __weak, because associated
// objects are only torn down after deallocation _finishes_ (and we need to
// avoid messaging the object as soon as it starts).
@interface MTLObserverLifecycleTracker : NSObject

@property (nonatomic, strong, readonly) id blockObserver;

- (id)initWithBlockObserver:(id)observer;

@end

@implementation NSNotificationCenter (MTLWeakReferenceAdditions)

- (id)mtl_addWeakObserver:(id)observerObject selector:(SEL)selector name:(NSString *)name object:(id)object {
	NSParameterAssert(observerObject != nil);
	NSParameterAssert(selector != NULL);

	// MTLObserverLifecycleTracker currently only communicates with the default
	// center.
	NSAssert([self isEqual:NSNotificationCenter.defaultCenter], @"%s does not support notification centers other than the default", __func__);

	NSAssert([observerObject methodSignatureForSelector:selector].numberOfArguments == 3, @"%s supports selectors with 1 and only 1 argument, %ld provided.", __func__, (long)([observerObject methodSignatureForSelector:selector].numberOfArguments - 2));

	__block id blockObserver;

	@weakify(observerObject);

	blockObserver = [self addObserverForName:name object:object queue:nil usingBlock:^(NSNotification *notification) {
		@strongify(observerObject);
		if (observerObject == nil) return;

		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[observerObject methodSignatureForSelector:selector]];
		invocation.target = observerObject;
		invocation.selector = selector;
		[invocation setArgument:&notification atIndex:2];
		[invocation invoke];
	}];

	MTLObserverLifecycleTracker *tracker = [[MTLObserverLifecycleTracker alloc] initWithBlockObserver:blockObserver];

	// Use the tracker itself as a unique key, to avoid collisions and since we
	// never need to remove it.
	objc_setAssociatedObject(observerObject, (__bridge void *)tracker, tracker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	return blockObserver;
}

@end

@implementation MTLObserverLifecycleTracker

- (id)initWithBlockObserver:(id)observer {
	NSParameterAssert(observer != nil);

	self = [super init];
	if (self == nil) return nil;

	_blockObserver = observer;
	return self;
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self.blockObserver];
}

@end
