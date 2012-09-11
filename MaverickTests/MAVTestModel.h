//
//  MAVTestModel.h
//  Maverick
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

@interface MAVTestModel : MAVModel

// Must be less than 10 characters.
@property (nonatomic, copy, readonly) NSString *name;

// Defaults to 1.
//
// Can be initialized from a string.
@property (nonatomic, assign, readonly) NSUInteger count;

@end
