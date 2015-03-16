# 2.0

This release of Mantle contains major breaking changes that we were unable to
make after freezing the 1.0 API.

The changes in 2.0 focus on simplifying concepts and increasing flexibility in
the framework.

For a complete list of the changes made in Mantle 2.0, see [the
milestone](https://github.com/Mantle/Mantle/issues?q=milestone%3A2.0+is%3Aclosed).

**[Breaking changes](#breaking-changes)**

 1. [Explicit JSON key paths](#explicit-json-key-paths)
 1. [Core Data adapter now separate](#core-data-adapter-now-separate)
 1. [OS X 10.9 and iOS 8](#os-x-109-and-ios-8)

**[Additions and improvements](#additions-and-improvements)**

 1. [MTLModel protocol](#mtlmodel-protocol)

## Breaking changes

### Explicit JSON key paths

`+JSONKeyPathsForPropertyKey` will [no
longer](https://github.com/Mantle/Mantle/pull/170) infer your property mappings
automatically.

Instead, you must explicitly specify every property that should
be mapped, and any properties omitted will not be considered for JSON
serialization or deserialization.

For convenience, you can use `+[NSDictionary mtl_identityPropertyMapWithModel:]`
to automatically create a one-to-one mapping that matches the previous default
behavior.

**To update:**

 * Explicitly declare any property mappings in `+JSONKeyPathsForPropertyKey`
   that were previously implicit.
 * Optionally use `+[NSDictionary mtl_identityPropertyMapWithModel:]` for an
   initial property map.

### Core Data adapter now separate

The `MTLManagedObjectAdapter` class, used for converting to and from Core Data
objects, has been moved to [its own
framework](https://github.com/Mantle/MTLManagedObjectAdapter). This better
indicates its “semi-official” status, as it gets less attention than the core
Mantle features.

**To update:**

 * Import the
   [MTLManagedObjectAdapter](https://github.com/Mantle/MTLManagedObjectAdapter)
   framework into your project.

### OS X 10.9 and iOS 8

Mantle now requires OS X 10.9+ or iOS 8+, for the use of Swift and dynamic
frameworks.

**To update:**

 * Increase your project’s deployment target to at least OS X 10.9 or iOS 8.

## Additions and improvements

### MTLModel protocol

The [new `<MTLModel>` protocol](https://github.com/Mantle/Mantle/pull/219) represents the basic behaviors expected from any
model object, and can be used instead of the `MTLModel` class when inheritance
is impossible, or to create more generic APIs.

For example, `<MTLModel>` conformance can be added to the objects from other
persistence frameworks in order to use those objects in conjunction with
Mantle’s adapters.

Accordingly, `MTLJSONAdapter` has been updated to only depend on `<MTLModel>`
conformance, and no longer requires a `MTLModel` subclass in order to serialize
or deserialize from JSON.
