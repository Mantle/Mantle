//
//  NSNotificationCenter+MTLWeakReferenceAdditions.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-26.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNotificationCenter (MTLWeakReferenceAdditions)

// Adds `observer` as an observer for the given notification, originating from
// the given object. If the `observer` is later deallocated, it is automatically
// unregistered from the notification.
//
// observer - The object upon which `selector` will be invoked when the specified
//            notification is posted. This object must support weak references.
// selector - The selector to invoke upon `object` when the specified
//            notification is posted. This selector must accept a single
//            argument of type `NSNotification *`.
// name     - The name of the notification to observe, or `nil` to not use the
//            notification name as a criterion for dispatch.
// object   - The object to observe for notifications, or `nil` to not use the
//            notification sender as a criterion for dispatch.
//
// Returns an opaque observer object which can later be passed to
// -removeObserver: or -removeObserver:name:object: to stop observation.
// (`observer` cannot be used for removal.)
- (id)mtl_addWeakObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)object;

@end
