//
//  MTLOptions.h
//  Mantle
//
//  Created by Sasha Zats on 2/16/14.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

typedef NS_OPTIONS(NSInteger, MTLParsingOptions) {
	// Allows to continue parsing of a model after validation errors or exception
	MTLParsingOptionCombineValidationErrors = (1UL << 0)
};
