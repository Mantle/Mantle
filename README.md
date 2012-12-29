# Mantle

Mantle makes it easy to write a simple model layer for your Cocoa or Cocoa Touch
application.

## Getting Started

Mantle is still new and moving fast, so we may make breaking changes from
time-to-time, but it has excellent unit test coverage and is already being used
in GitHub for Mac's production code.

To start building the framework, clone this repository and then run `git
submodule update --init --recursive`. This will automatically pull down any
dependencies.

## The Typical Model Object

What's wrong with the way model objects are usually written in Objective-C?

Let's use the [GitHub API](http://developer.github.com) for demonstration. How
would one typically represent a [GitHub
issue](http://developer.github.com/v3/issues/#get-a-single-issue) in
Objective-C?

```objc
typedef enum : NSUInteger {
    GHIssueStateOpen,
    GHIssueStateClosed
} GHIssueState;

@interface GHIssue : NSObject <NSCoding, NSCopying>

@property (nonatomic, copy, readonly) NSURL *URL;
@property (nonatomic, copy, readonly) NSURL *HTMLURL;
@property (nonatomic, copy, readonly) NSNumber *number;
@property (nonatomic, assign, readonly) GHIssueState state;
@property (nonatomic, copy, readonly) NSString *reporterLogin;
@property (nonatomic, copy, readonly) NSString *assigneeLogin;
@property (nonatomic, copy, readonly) NSDate *updatedAt;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end
```

```objc
@implementation GHIssue

+ (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    return dateFormatter;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [self init];
    if (self == nil) return nil;

    _URL = [NSURL URLWithString:dictionary[@"url"]];
    _HTMLURL = [NSURL URLWithString:dictionary[@"html_url"]];
    _number = dictionary[@"number"];
    
    if ([dictionary[@"state"] isEqualToString:@"open"]) {
        _state = GHIssueStateOpen;
    } else if ([dictionary[@"state"] isEqualToString:@"closed"]) {
        _state = GHIssueStateClosed;
    }

    _title = [dictionary[@"title"] copy];
    _body = [dictionary[@"body"] copy];
    _reporterLogin = [dictionary[@"user"][@"login"] copy];
    _assigneeLogin = [dictionary[@"assignee"][@"login"] copy];

    _updatedAt = [self.class.dateFormatter dateFromString:dictionary[@"updated_at"]];

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [self init];
    if (self == nil) return nil;

    _URL = [coder decodeObjectForKey:@"URL"];
    _HTMLURL = [coder decodeObjectForKey:@"HTMLURL"];
    _number = [coder decodeObjectForKey:@"number"];
    _state = [coder decodeUnsignedIntegerForKey:@"state"];
    _title = [coder decodeObjectForKey:@"title"];
    _body = [coder decodeObjectForKey:@"body"];
    _reporterLogin = [coder decodeObjectForKey:@"reporterLogin"];
    _assigneeLogin = [coder decodeObjectForKey:@"assigneeLogin"];
    _updatedAt = [coder decodeObjectForKey:@"updatedAt"];

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.URL != nil) [coder encodeObject:self.URL forKey:@"URL"];
    if (self.HTMLURL != nil) [coder encodeObject:self.HTMLURL forKey:@"HTMLURL"];
    if (self.number != nil) [coder encodeObject:self.number forKey:@"number"];
    if (self.title != nil) [coder encodeObject:self.title forKey:@"title"];
    if (self.body != nil) [coder encodeObject:self.body forKey:@"body"];
    if (self.reporterLogin != nil) [coder encodeObject:self.reporterLogin forKey:@"reporterLogin"];
    if (self.assigneeLogin != nil) [coder encodeObject:self.assigneeLogin forKey:@"assigneeLogin"];
    if (self.updatedAt != nil) [coder encodeObject:self.updatedAt forKey:@"updatedAt"];

    [coder encodeUnsignedInteger:self.state forKey:@"state"];
}

- (id)copyWithZone:(NSZone *)zone {
    GHIssue *issue = [[self.class allocWithZone:zone] init];
    issue->_URL = self.URL;
    issue->_HTMLURL = self.HTMLURL;
    issue->_number = self.number;
    issue->_state = self.state;
    issue->_reporterLogin = self.reporterLogin;
    issue->_assigneeLogin = self.assigneeLogin;
    issue->_updatedAt = self.updatedAt;

    issue.title = self.title;
    issue.body = self.body;
}

- (NSUInteger)hash {
    return self.number.hash;
}

- (BOOL)isEqual:(GHIssue *)issue {
    if (![issue isKindOfClass:GHIssue.class]) return NO;

    return [self.number isEqual:issue.number] && [self.title isEqual:issue.title] && [self.body isEqual:issue.body];
}

@end
```

Whew, that's a lot of boilerplate for something so simple! And, even then, there
are some problems that this example doesn't address:

 * If the `url` or `html_url` field is missing, `+[NSURL URLWithString:]` will throw an exception.
 * There's no way to update a `GHIssue` with new data from the server.
 * There's no way to turn a `GHIssue` _back_ into JSON.
 * `GHIssueState` shouldn't be encoded as-is. If the enum changes in the future, existing archives might break.
 * If the interface of `GHIssue` changes down the road, existing archives might break.

## Why Not Use Core Data?

Core Data solves certain problems very well. If you need to execute complex
queries across your data, handle a huge object graph with lots of relationships,
or support undo and redo, Core Data is an excellent fit.

It does, however, come with a couple of pain points:

 * **There's still a lot of boilerplate.** Managed objects reduce some of the
   boilerplate seen above, but Core Data has plenty of its own. Correctly
   setting up a Core Data stack (with a persistent store and persistent store
   coordinator) and executing fetches can take many lines of code.
 * **It's hard to get right.** Even experienced developers can make mistakes
   when using Core Data, and the framework is not forgiving.

If you're just trying to access some JSON objects, Core Data can be a lot of
work for little gain.

Nonetheless, if you're using or want to use Core Data in your app already,
Mantle can still be a convenient translation layer between the API and your managed
model objects.

## MTLModel

Enter
**[MTLModel](https://github.com/github/Mantle/blob/master/Mantle/MTLModel.h)**.
This is what `GHIssue` looks like inheriting from `MTLModel`:

```objc
typedef enum : NSUInteger {
    GHIssueStateOpen,
    GHIssueStateClosed
} GHIssueState;

@interface GHIssue : MTLModel

@property (nonatomic, copy, readonly) NSURL *URL;
@property (nonatomic, copy, readonly) NSURL *HTMLURL;
@property (nonatomic, copy, readonly) NSNumber *number;
@property (nonatomic, assign, readonly) GHIssueState state;
@property (nonatomic, copy, readonly) NSString *reporterLogin;
@property (nonatomic, copy, readonly) NSString *assigneeLogin;
@property (nonatomic, copy, readonly) NSDate *updatedAt;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;

@end
```

```objc
@implementation GHIssue

+ (NSDateFormatter *)dateFormatter {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    return dateFormatter;
}

+ (NSDictionary *)externalRepresentationKeyPathsByPropertyKey {
    return [super.externalRepresentationKeyPathsByPropertyKey mtl_dictionaryByAddingEntriesFromDictionary:@{
        @"URL": @"url",
        @"HTMLURL": @"html_url",
        @"reporterLogin": @"user.login",
        @"assigneeLogin": @"assignee.login",
        @"updatedAt": @"updated_at"
    }];
}

+ (NSValueTransformer *)URLTransformer {
	return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)HTMLURLTransformer {
	return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)stateTransformer {
    NSDictionary *states = @{
        @"open": @(GHIssueStateOpen),
        @"closed": @(GHIssueStateClosed)
    };

    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return states[str];
    } reverseBlock:^(NSNumber *state) {
        return [states allKeysForObject:state].lastObject;
    }];
}

+ (NSValueTransformer *)updatedAtTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return [self.dateFormatter dateFromString:str];
    } reverseBlock:^(NSDate *date) {
        return [self.dateFormatter stringFromDate:date];
    }];
}

@end
```

Notably absent from this version are implementations of `<NSCoding>`,
`<NSCopying>`, `-isEqual:`, and `-hash`. By inspecting the `@property`
declarations you have in your subclass, `MTLModel` can provide default
implementations for all these methods.

The problems with the original example all happen to be fixed as well:

> * If the `url` or `html_url` field is missing, `+[NSURL URLWithString:]` will throw an exception.

The URL transformer we used (included in Mantle) returns `nil` if given a `nil`
string.

> * There's no way to update a `GHIssue` with new data from the server.

`MTLModel` has an extensible `-mergeValuesForKeysFromModel:` method, which makes
it easy to specify how new model data should be integrated.

> * There's no way to turn a `GHIssue` _back_ into JSON.
> * `GHIssueState` shouldn't be encoded as-is. If the enum changes in the future, existing archives might break.

_Both_ of these issues are solved by using reversible transformers.
`-[GHIssue externalRepresentation]` will return a JSON dictionary, which is also
what gets encoded in `-encodeWithCoder:`. No saving fragile enum values!

> * If the interface of `GHIssue` changes down the road, existing archives might break.

`MTLModel` automatically saves the version of the model object that was used for
archival. When unarchiving, `+migrateExternalRepresentation:fromVersion:` will
be invoked if migration is needed, giving you a convenient hook to upgrade old
data.

## Persistence

Mantle doesn't automatically persist your objects for you. However, `MTLModel`
does conform to `<NSCoding>`, so model objects can be archived to disk using
`NSKeyedArchiver`.

If you need something more powerful, or want to avoid keeping your whole model
in memory at once, Core Data may be a better choice.

## Other Extensions

Mantle also comes with miscellaneous cross-platform extensions meant to
make your life easier, including:

 * **Higher-order functions** (`map`, `filter`, `fold`) for
   [NSArray](https://github.com/github/Mantle/blob/master/Mantle/NSArray%2BMTLHigherOrderAdditions.h),
   [NSDictionary](https://github.com/github/Mantle/blob/master/Mantle/NSDictionary%2BMTLHigherOrderAdditions.h),
   [NSOrderedSet](https://github.com/github/Mantle/blob/master/Mantle/NSOrderedSet%2BMTLHigherOrderAdditions.h),
   and [NSSet](https://github.com/github/Mantle/blob/master/Mantle/NSSet%2BMTLHigherOrderAdditions.h).
 * **[Weak notification center observers](https://github.com/github/Mantle/blob/master/Mantle/NSNotificationCenter%2BMTLWeakReferenceAdditions.h)**

There will assuredly be more, as we run into other common pain points!

## License

Mantle is released under the MIT license. See
[LICENSE.md](https://github.com/github/Mantle/blob/master/LICENSE.md).
