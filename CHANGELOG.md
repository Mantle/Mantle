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

**[Additions and improvements](#additions-and-improvements)**

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

## Additions and improvements
