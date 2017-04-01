//
//  MTLJSONKeyPath.h
//  Mantle
//
//  Created by Will Lisac on 3/31/17.
//  Copyright © 2017 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A class used to represent a JSON key path by discrete key components.
@interface MTLJSONKeyPath : NSObject <NSCopying>

/// An array of JSON keys that represent a JSON key path.
///
/// This property will never be nil.
@property (nonatomic, strong, readonly) NSArray<NSString *> *components;

/// Initializes the receiver with the given JSON key components.
///
/// components - The array of JSON keys that represent a JSON key path.
///              This argument must not be nil.
///
/// Returns an initialized JSON Key path.
- (instancetype)initWithComponents:(NSArray<NSString *> *)components;

@end

/// MTLKeyPath is a macro that initializes and returns a MTLJSONKeyPath
/// object with the given JSON key components.
#define MTLKeyPath(...) \
	[[MTLJSONKeyPath alloc] initWithComponents:@[__VA_ARGS__]]

NS_ASSUME_NONNULL_END
