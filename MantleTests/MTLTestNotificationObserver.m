//
//  MTLTestNotificationObserver.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-26.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "MTLTestNotificationObserver.h"

@interface MTLTestNotificationObserver ()
@property (nonatomic, assign, readwrite) BOOL receivedNotification;
@end

@implementation MTLTestNotificationObserver

- (void)notificationPosted:(NSNotification *)notification {
	NSParameterAssert(notification != nil);

	NSAssert(!self.receivedNotification, @"Should receive a single notification: %@", notification);
	self.receivedNotification = YES;
}

@end
