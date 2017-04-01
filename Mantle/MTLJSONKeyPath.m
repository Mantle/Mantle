//
//  MTLJSONKeyPath.m
//  Mantle
//
//  Created by Will Lisac on 3/31/17.
//  Copyright © 2017 GitHub. All rights reserved.
//

#import "MTLJSONKeyPath.h"

@interface MTLJSONKeyPath ()

@property (nonatomic, strong, readwrite) NSArray *components;

@end

@implementation MTLJSONKeyPath

- (instancetype)initWithComponents:(NSArray<NSString *> *)components {
	self = [super init];
	if (self == nil) return nil;
	
	self.components = components;
	
	return self;
}

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	MTLJSONKeyPath *copy = [[self.class allocWithZone:zone] init];
	copy.components = [self.components copy];
	return copy;
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, self.components];
}

- (NSUInteger)hash {
	return [self.components hash];
}

- (BOOL)isEqual:(MTLJSONKeyPath *)object {
	if (self == object) return YES;
	if (![object isMemberOfClass:self.class]) return NO;
	
	return [self.components isEqualToArray:object.components];
}

@end
