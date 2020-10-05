//
//  Mantle.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-04.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for Mantle.
FOUNDATION_EXPORT double MantleVersionNumber;

//! Project version string for Mantle.
FOUNDATION_EXPORT const unsigned char MantleVersionString[];

#if __has_include(<Mantle/Mantle.h>)
#import <Mantle/MTLJSONAdapter.h>
#import <Mantle/MTLModel.h>
#import <Mantle/MTLModel+NSCoding.h>
#import <Mantle/MTLValueTransformer.h>
#import <Mantle/MTLTransformerErrorHandling.h>
#import <Mantle/NSArray+MTLManipulationAdditions.h>
#import <Mantle/NSDictionary+MTLManipulationAdditions.h>
#import <Mantle/NSDictionary+MTLMappingAdditions.h>
#import <Mantle/NSObject+MTLComparisonAdditions.h>
#import <Mantle/NSValueTransformer+MTLInversionAdditions.h>
#import <Mantle/NSValueTransformer+MTLPredefinedTransformerAdditions.h>
#else
#import "MTLJSONAdapter.h"
#import "MTLModel.h"
#import "MTLModel+NSCoding.h"
#import "MTLValueTransformer.h"
#import "MTLTransformerErrorHandling.h"
#import "NSArray+MTLManipulationAdditions.h"
#import "NSDictionary+MTLManipulationAdditions.h"
#import "NSDictionary+MTLMappingAdditions.h"
#import "NSObject+MTLComparisonAdditions.h"
#import "NSValueTransformer+MTLInversionAdditions.h"
#import "NSValueTransformer+MTLPredefinedTransformerAdditions.h"
#endif
