//
//  MTLOptions.h
//  Mantle
//
//  Created by Sasha Zats on 2/16/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

// Options used when creating MTLModel objects from data,
// see MTLParsingOptionCombineValidationErrors.
typedef NS_OPTIONS(NSInteger, MTLParsingOptions) {
	// Allows to continue parsing of a model after validation errors or exception
	MTLParsingOptionCombineValidationErrors = (1UL << 0)
};
