//
//  MTLReflection.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLReflection.h"
#import <objc/runtime.h>

SEL MTLSelectorWithKeyPattern(NSString *key, NSString *suffix) {
	NSUInteger keyLength = [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	NSUInteger suffixLength = [suffix lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	char selector[keyLength + suffixLength + 1];
	memcpy(selector, key.UTF8String, keyLength);
	memcpy(selector + keyLength, suffix.UTF8String, suffixLength);
	selector[sizeof(selector) - 1] = '\0';

	return sel_registerName(selector);
}

SEL MTLSelectorWithCapitalizedKeyPattern(NSString *prefix, NSString *key, NSString *suffix) {
	NSUInteger prefixLength = [prefix lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	NSUInteger suffixLength = [suffix lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	NSString *initial = [key substringToIndex:1].uppercaseString;
	NSUInteger initialLength = [initial lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	NSString *rest = [key substringFromIndex:1];
	NSUInteger restLength = [rest lengthOfBytesUsingEncoding:NSUTF8StringEncoding];

	char selector[prefixLength + initialLength + restLength + suffixLength + 1];
	memcpy(selector, prefix.UTF8String, prefixLength);
	memcpy(selector + prefixLength, initial.UTF8String, initialLength);
	memcpy(selector + prefixLength + initialLength, rest.UTF8String, restLength);
	memcpy(selector + prefixLength + initialLength + restLength, suffix.UTF8String, suffixLength);
	selector[sizeof(selector) - 1] = '\0';

	return sel_registerName(selector);
}
