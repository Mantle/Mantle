//
//  MAVTestModel.h
//  Maverick
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

@interface MAVTestModel : MAVModel

@property (nonatomic, copy, readonly) NSString *name;

// Defaults to 1.
@property (nonatomic, assign, readonly) NSUInteger count;

@end
