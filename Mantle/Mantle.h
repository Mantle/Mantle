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
