//
//  MTLReflection.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLReflection.h"
#import <objc/runtime.h>

SEL MTLSelectorWithKeyPattern(NSString *key, const char *suffix) {
	NSUInteger keyLength = [key maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	NSUInteger suffixLength = strlen(suffix);

	char selector[keyLength + suffixLength + 1];

	BOOL success = [key getBytes:selector maxLength:keyLength usedLength:&keyLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, key.length) remainingRange:NULL];
	if (!success) return NULL;

	memcpy(selector + keyLength, suffix, suffixLength);
	selector[keyLength + suffixLength] = '\0';

	return sel_registerName(selector);
}

SEL MTLSelectorWithCapitalizedKeyPattern(const char *prefix, NSString *key, const char *suffix) {
	NSUInteger prefixLength = strlen(prefix);
	NSUInteger suffixLength = strlen(suffix);
	NSUInteger keyLength = [key maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	NSUInteger initialLength = 1; // this is always 1 since we're making just the first character uppercase
	NSUInteger restLength;
	char selector[prefixLength + keyLength + suffixLength + 1];

	memcpy(selector, prefix, prefixLength);

	selector[prefixLength] = (char)toupper([key characterAtIndex:0]); // casting from unichar to char, but sel_registerName only takes a char anyways

	BOOL success = [key getBytes:selector + prefixLength + initialLength maxLength:keyLength - 1 usedLength:&restLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(1, key.length - 1) remainingRange:NULL];
	if (!success) return NULL;

	memcpy(selector + prefixLength + initialLength + restLength, suffix, suffixLength);
	selector[prefixLength + initialLength + restLength + suffixLength] = '\0';

	return sel_registerName(selector);
}
