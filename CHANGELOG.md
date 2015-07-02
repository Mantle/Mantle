# 2.0

This release of Mantle contains major breaking changes that we were unable to
make after freezing the 1.0 API.

The changes in 2.0 focus on simplifying concepts and increasing flexibility in
the framework.

For a complete list of the changes made in Mantle 2.0, see [the
milestone](https://github.com/Mantle/Mantle/issues?q=milestone%3A2.0+is%3Aclosed).

**[Breaking changes](#breaking-changes)**

 1. [Explicit JSON key paths](#explicit-json-key-paths)
 1. [Predefined transformers now part of JSON adapter](#predefined-transformers-now-part-of-json-adapter)
 1. [Core Data adapter now separate](#core-data-adapter-now-separate)
 1. [Managed object transformers reversed](#managed-object-transformers-reversed)
 1. [OS X 10.9 and iOS 8](#os-x-109-and-ios-8)
 1. [JSON key paths can only traverse objects](#json-key-paths-can-only-traverse-objects)

**[Additions and improvements](#additions-and-improvements)**

 1. [MTLModel protocol](#mtlmodel-protocol)
 1. [Error handling for value transformers](#error-handling-for-value-transformers)
 1. [Storage behaviors for properties](#storage-behaviors-for-properties)
 1. [Type checking during JSON parsing](#type-checking-during-json-parsing)
 1. [Mapping multiple JSON fields to a single property](#mapping-multiple-json-fields-to-a-single-property)

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

### Predefined transformers now part of JSON adapter

The `+mtl_JSONDictionaryTransformerWithModelClass:` and
`+mtl_JSONArrayWithModelClass:` methods [have
moved](https://github.com/Mantle/Mantle/pull/474) to `MTLJSONAdapter`.

This allows custom JSON adapter subclasses to substitute their own transformers
with additional logic, and moves the transformers closer to their actual point
of use.

**To update:**

 * Replace occurrences of `+[NSValueTransformer
   mtl_JSONDictionaryTransformerWithModelClass:]` with `+[MTLJSONAdapter
   dictionaryTransformerWithModelClass:]`
 * Replace occurrences of `+[NSValueTransformer
   mtl_JSONArrayTransformerWithModelClass:]` with `+[MTLJSONAdapter
   arrayTransformerWithModelClass:]`

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

### Managed object transformers reversed

In addition to being [a separate framework](#core-data-adapter-now-separate),
the behavior of `MTLManagedObjectAdapter` has changed as well—specifically, the
direction of managed object attribute transformers has been flipped.

Managed object transformers now convert _from_ managed object attributes _to_
model properties in the forward direction. In the reverse direction, they
convert from properties to managed object attributes.

**To update:**

 * Swap the forward and reverse transformation logic of any custom managed
   object transformers, or use `-mtl_invertedTransformer` to do it
   automatically.

### OS X 10.9 and iOS 8

Mantle now requires OS X 10.9+ or iOS 8+, for the use of Swift and dynamic
frameworks.

**To update:**

 * Increase your project’s deployment target to at least OS X 10.9 or iOS 8.

### JSON key paths can only traverse objects

Every element of a JSON key path specified in `+JSONKeyPathsByPropertyKey` [must
now refer to an object](https://github.com/Mantle/Mantle/pull/275) (dictionary).

It was [previously possible](https://github.com/Mantle/Mantle/issues/257) to use
an array as a key path element, but this was unintended behavior, and is now
explicitly disallowed.

**To update:**

 * If you were using an array as an element in a key path, change the key path
   to end at the array, and [update your JSON transformer](https://github.com/Mantle/Mantle/issues/257#issuecomment-36846503)
   to handle the nested elements instead.

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

### Error handling for value transformers

The [new `<MTLTransformerErrorHandling>`
protocol](https://github.com/Mantle/Mantle/pull/153) can be used to add error
reporting behaviors to any `NSValueTransformer`.

`MTLValueTransformer` has been updated to take advantage of the new interface,
with the following new methods that provide error information:

 * `+transformerUsingForwardBlock:`
 * `+transformerUsingReversibleBlock:`
 * `+transformerUsingForwardBlock:reverseBlock:`

Similarly, the predefined transformers that Mantle provides now provide error
information upon failure as well.

### Storage behaviors for properties

The [new `+storageBehaviorForPropertyWithKey:`
method](https://github.com/Mantle/Mantle/pull/210) can be used to redefine the
default behavior of methods like `-dictionaryValue`, `-isEqual:`,
`-description`, and `-copy` all at once.

Properties which have been omitted from `+propertyKeys` by default will continue
to be omitted under the new API, with a default behavior of
`MTLPropertyStorageNone`.

### Type checking during JSON parsing

`MTLJSONAdapter` now [implicitly
validates](https://github.com/Mantle/Mantle/pull/251) the type of values
assigned to your `<MTLModel>` objects during JSON parsing.

This can be prevent errors like an `NSString` being assigned to a `BOOL`
property.

This is only a simple safety check, though, and cannot catch every kind of
error! Continue to verify that your types align ahead of time.

### Mapping multiple JSON fields to a single property

`MTLJSONAdapter` can now map multiple fields to a single property, and 
vice-versa. Specify an array of keypaths for the property when implementing 
`+JSONKeyPathsByPropertyKey` rather than an `NSString`.

The default behaviour is to set the property to a dictionary of values for the 
specified keypaths. If you specify a value transformer for the given property 
key, this transformer will receive an `NSDictionary` of values.
