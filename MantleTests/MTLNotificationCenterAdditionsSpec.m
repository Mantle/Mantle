//
//  MTLNotificationCenterAdditionsSpec.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-26.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestNotificationObserver.h"

SpecBegin(MTLNotificationCenterAdditions)

NSString *notificationName = @"MTLNotificationCenterAdditionsNotification";

it(@"should send notifications to weak observers", ^{
	MTLTestNotificationObserver *observer = [[MTLTestNotificationObserver alloc] init];
	expect(observer).notTo.beNil();

	id token = [NSNotificationCenter.defaultCenter mtl_addWeakObserver:observer selector:@selector(notificationPosted:) name:notificationName object:self];
	expect(token).notTo.beNil();

	expect(observer.receivedNotification).to.beFalsy();
	[NSNotificationCenter.defaultCenter postNotificationName:notificationName object:self];
	expect(observer.receivedNotification).to.beTruthy();

	[NSNotificationCenter.defaultCenter removeObserver:token];

	// The observer shouldn't receive this notification. (It'll throw an
	// assertion if it does.)
	[NSNotificationCenter.defaultCenter postNotificationName:notificationName object:self];
});

it(@"should unregister from notifications if the observer is deallocated", ^{
	__weak id weakObserver = nil;

	@autoreleasepool {
		MTLTestNotificationObserver *observer __attribute__((objc_precise_lifetime)) = [[MTLTestNotificationObserver alloc] init];

		weakObserver = observer;
		expect(weakObserver).notTo.beNil();

		[NSNotificationCenter.defaultCenter mtl_addWeakObserver:observer selector:@selector(notificationPosted:) name:notificationName object:self];
	}

	expect(weakObserver).to.beNil();

	// Should do nothing.
	[NSNotificationCenter.defaultCenter postNotificationName:notificationName object:self];
});

SpecEnd
