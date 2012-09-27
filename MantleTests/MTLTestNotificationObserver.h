//
//  MTLTestNotificationObserver.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-26.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTLTestNotificationObserver : NSObject

@property (nonatomic, assign, readonly) BOOL receivedNotification;

// Should only be invoked once.
- (void)notificationPosted:(NSNotification *)notification;

@end
