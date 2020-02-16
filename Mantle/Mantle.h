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

// These imports should not be visible to SPM & SPM doesn't seem to have the target "exclude" apply to headers
// & publicHeadersPath is a single string, so can't just list all the headers we want unless we move them into a folder
#if MANTLE_SPM

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

#endif /* MANTLE_SPM */
