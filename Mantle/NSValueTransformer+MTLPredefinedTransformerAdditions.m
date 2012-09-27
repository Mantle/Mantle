//
//  NSValueTransformer+MTLPredefinedTransformerAdditions.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-27.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#import "MTLValueTransformer.h"

NSString * const MTLURLValueTransformerName = @"MTLURLValueTransformerName";

@implementation NSValueTransformer (MTLPredefinedTransformerAdditions)

#pragma mark Category Loading

+ (void)load {
	MTLValueTransformer *URLValueTransformer = [MTLValueTransformer
		reversibleTransformerWithForwardBlock:^ id (NSString *str) {
			if (![str isKindOfClass:NSString.class]) return nil;
			return [NSURL URLWithString:str];
		}
		reverseBlock:^ id (NSURL *URL) {
			if (![URL isKindOfClass:NSURL.class]) return nil;
			return URL.absoluteString;
		}];
	
	[NSValueTransformer setValueTransformer:URLValueTransformer forName:MTLURLValueTransformerName];
}

@end
