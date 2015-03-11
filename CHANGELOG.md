# Change Log

## [Unreleased](https://github.com/Mantle/Mantle/tree/HEAD)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.5.4...HEAD)

**Implemented enhancements:**

- MTLURLValueTransformerName doesn't work for Url with UTF8 characters. [\#456](https://github.com/Mantle/Mantle/issues/456)

**Fixed bugs:**

- Install issue [\#426](https://github.com/Mantle/Mantle/issues/426)

**Closed issues:**

- Crash when convert NSString to BOOL [\#466](https://github.com/Mantle/Mantle/issues/466)

- Same JSONTransformer for multiple properties of the same type [\#449](https://github.com/Mantle/Mantle/issues/449)

- Strange Core Data Fetching Behavior after Network Call [\#447](https://github.com/Mantle/Mantle/issues/447)

- How Mantle parse two model which have inheritance relationship? [\#443](https://github.com/Mantle/Mantle/issues/443)

- Compilation error when using cocoapods' new framework system [\#438](https://github.com/Mantle/Mantle/issues/438)

- initWithDictionary: error: does not respect MTLJSONSerializing [\#225](https://github.com/Mantle/Mantle/issues/225)

**Merged pull requests:**

- Solved the problem of attribute type transform and "response" shows null [\#463](https://github.com/Mantle/Mantle/pull/463) ([ianisme](https://github.com/ianisme))

- Solved the problem of attribute type transform and "response" shows null [\#462](https://github.com/Mantle/Mantle/pull/462) ([ianisme](https://github.com/ianisme))

- Solved the problem of attribute type transform and "response" shows null   [\#461](https://github.com/Mantle/Mantle/pull/461) ([ianisme](https://github.com/ianisme))

- Allow multiple JSON fields [\#459](https://github.com/Mantle/Mantle/pull/459) ([rickytribbia](https://github.com/rickytribbia))

- MTLSelectorWithCapitalizedKeyPattern optimizations: Use toupper instead of substringToIndex/uppercaseString [\#458](https://github.com/Mantle/Mantle/pull/458) ([ksuther](https://github.com/ksuther))

- Uniquing capability for MTLModels [\#457](https://github.com/Mantle/Mantle/pull/457) ([Ricowere](https://github.com/Ricowere))

- MTLManagedObjectAdapter ordered sets on relationships [\#454](https://github.com/Mantle/Mantle/pull/454) ([Ricowere](https://github.com/Ricowere))

- fix a typo [\#440](https://github.com/Mantle/Mantle/pull/440) ([bifidy](https://github.com/bifidy))

- Fixed incorrect error descriptions in JSONArray transformer [\#240](https://github.com/Mantle/Mantle/pull/240) ([dcaunt](https://github.com/dcaunt))

## [1.5.4](https://github.com/Mantle/Mantle/tree/1.5.4) (2015-01-16)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.5.3...1.5.4)

**Closed issues:**

- Update CocoaPods podspec to 1.5.3 [\#432](https://github.com/Mantle/Mantle/issues/432)

**Merged pull requests:**

- Pacify Xcode [\#437](https://github.com/Mantle/Mantle/pull/437) ([joshaber](https://github.com/joshaber))

- Namespaced keys addition [\#403](https://github.com/Mantle/Mantle/pull/403) ([bnd5k](https://github.com/bnd5k))

## [1.5.3](https://github.com/Mantle/Mantle/tree/1.5.3) (2014-12-30)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.5.2...1.5.3)

**Closed issues:**

- Carthage building fails [\#428](https://github.com/Mantle/Mantle/issues/428)

- Mantle Podspecs link on the README is broken [\#418](https://github.com/Mantle/Mantle/issues/418)

**Merged pull requests:**

- Migrate to Carthage 0.5 [\#431](https://github.com/Mantle/Mantle/pull/431) ([jspahrsummers](https://github.com/jspahrsummers))

- Mtlmanagedobject [\#424](https://github.com/Mantle/Mantle/pull/424) ([trantuan10t2](https://github.com/trantuan10t2))

- Remove mention of Slack chat room [\#422](https://github.com/Mantle/Mantle/pull/422) ([jspahrsummers](https://github.com/jspahrsummers))

- Only build the tests when testing. [\#420](https://github.com/Mantle/Mantle/pull/420) ([robrix](https://github.com/robrix))

- Updated Specs URL in README [\#419](https://github.com/Mantle/Mantle/pull/419) ([dcaunt](https://github.com/dcaunt))

- MTLValueTransformer improvements for inheritance [\#417](https://github.com/Mantle/Mantle/pull/417) ([knox](https://github.com/knox))

## [1.5.2](https://github.com/Mantle/Mantle/tree/1.5.2) (2014-11-21)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.5.1...1.5.2)

**Closed issues:**

- JSONMantle doesn't compile in XCode 6 and IOS 8 target  [\#398](https://github.com/Mantle/Mantle/issues/398)

- App crashes on iPad2 where as works in Simulator \(iPad2\) [\#391](https://github.com/Mantle/Mantle/issues/391)

- Crashes on Xcode 6 [\#387](https://github.com/Mantle/Mantle/issues/387)

- Mantle incorrectly caches +propertyKeys when the first object has a NULL value for a readonly prop [\#383](https://github.com/Mantle/Mantle/issues/383)

- What is a proper way to validate present of mandatory field [\#256](https://github.com/Mantle/Mantle/issues/256)

- @MantleFramework needs a logo [\#201](https://github.com/Mantle/Mantle/issues/201)

**Merged pull requests:**

- Use Carthage to manage submodules [\#413](https://github.com/Mantle/Mantle/pull/413) ([jspahrsummers](https://github.com/jspahrsummers))

- Xcode 6.1 support \(2.0-development edition\) [\#410](https://github.com/Mantle/Mantle/pull/410) ([jspahrsummers](https://github.com/jspahrsummers))

- Upgrade Quick [\#407](https://github.com/Mantle/Mantle/pull/407) ([jspahrsummers](https://github.com/jspahrsummers))

- Add Dependency & Reference Badge to README [\#380](https://github.com/Mantle/Mantle/pull/380) ([reiz](https://github.com/reiz))

- Fixes collisions with libextobjc [\#377](https://github.com/Mantle/Mantle/pull/377) ([Club15CC](https://github.com/Club15CC))

- Xcode 6.1 support [\#369](https://github.com/Mantle/Mantle/pull/369) ([jspahrsummers](https://github.com/jspahrsummers))

## [1.5.1](https://github.com/Mantle/Mantle/tree/1.5.1) (2014-07-30)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.5...1.5.1)

**Implemented enhancements:**

- -initWithDictionary should set nil values [\#321](https://github.com/Mantle/Mantle/issues/321)

- Longer-lived adapters [\#151](https://github.com/Mantle/Mantle/issues/151)

**Fixed bugs:**

- \(kind of\) breaking change in 1.5 [\#331](https://github.com/Mantle/Mantle/issues/331)

**Closed issues:**

- firstObject [\#372](https://github.com/Mantle/Mantle/issues/372)

- +URLWithString: no longer throws on nil [\#370](https://github.com/Mantle/Mantle/issues/370)

- Removing Core Data support from Mantle in 2.0 [\#356](https://github.com/Mantle/Mantle/issues/356)

- Unknown type name - libffi [\#353](https://github.com/Mantle/Mantle/issues/353)

- As an FYI, regarding Mantle and Swift [\#342](https://github.com/Mantle/Mantle/issues/342)

- Metal prefixes [\#341](https://github.com/Mantle/Mantle/issues/341)

- Add a tagged release \(1.4.2 or 1.5\) [\#327](https://github.com/Mantle/Mantle/issues/327)

- Transform REST response to array of models [\#322](https://github.com/Mantle/Mantle/issues/322)

- Assert against nil values in initWithJSONDictionary:modelClass: [\#148](https://github.com/Mantle/Mantle/issues/148)

**Merged pull requests:**

- Fix typo in README. [\#376](https://github.com/Mantle/Mantle/pull/376) ([tomtaylor](https://github.com/tomtaylor))

- Remove Core Data code [\#374](https://github.com/Mantle/Mantle/pull/374) ([robb](https://github.com/robb))

- Zero warnings [\#368](https://github.com/Mantle/Mantle/pull/368) ([mdiep](https://github.com/mdiep))

- Remove test that's invalid because of \#349 [\#367](https://github.com/Mantle/Mantle/pull/367) ([mdiep](https://github.com/mdiep))

- Add documentation around overriding `initWithDictionary:error:` [\#365](https://github.com/Mantle/Mantle/pull/365) ([mickeyreiss](https://github.com/mickeyreiss))

- Move to specta/specta, specta/expecta, and XCTest [\#364](https://github.com/Mantle/Mantle/pull/364) ([mdiep](https://github.com/mdiep))

- fix grammar in error message [\#363](https://github.com/Mantle/Mantle/pull/363) ([5teev](https://github.com/5teev))

- Core data model [\#362](https://github.com/Mantle/Mantle/pull/362) ([ciotto](https://github.com/ciotto))

- Core data model [\#361](https://github.com/Mantle/Mantle/pull/361) ([ciotto](https://github.com/ciotto))

- IGNORE THIS -Modified Mantle to support keys with periods in the name. [\#360](https://github.com/Mantle/Mantle/pull/360) ([dan-ssi](https://github.com/dan-ssi))

- Add Slack chat room to README [\#357](https://github.com/Mantle/Mantle/pull/357) ([jspahrsummers](https://github.com/jspahrsummers))

- Ordered relationship deserialization to NSOrderedSet vs NSMutableArray [\#352](https://github.com/Mantle/Mantle/pull/352) ([rawrjustin](https://github.com/rawrjustin))

- backport exception for invalid JSONKeyPathsByPropertyKey [\#349](https://github.com/Mantle/Mantle/pull/349) ([Ahti](https://github.com/Ahti))

- Change -initWithDictionary:error: to call super [\#348](https://github.com/Mantle/Mantle/pull/348) ([maxgoedjen](https://github.com/maxgoedjen))

- Docs fix [\#345](https://github.com/Mantle/Mantle/pull/345) ([robb](https://github.com/robb))

- Correctly deprecate -mtl\_dictionaryByRemovingEntriesWithKeys: [\#338](https://github.com/Mantle/Mantle/pull/338) ([robb](https://github.com/robb))

- Automatically validate models from JSON data [\#335](https://github.com/Mantle/Mantle/pull/335) ([robb](https://github.com/robb))

- Throw an exception for illegal JSON mappings [\#325](https://github.com/Mantle/Mantle/pull/325) ([robb](https://github.com/robb))

- Exposed existing managed object fetching in MTLManagedObjectAdapter [\#324](https://github.com/Mantle/Mantle/pull/324) ([nickynick](https://github.com/nickynick))

- Handle nil transformers [\#320](https://github.com/Mantle/Mantle/pull/320) ([robb](https://github.com/robb))

- Include a test for not deleting an existing object on validation error [\#315](https://github.com/Mantle/Mantle/pull/315) ([kylef](https://github.com/kylef))

- Add convenience method inserting arrays [\#314](https://github.com/Mantle/Mantle/pull/314) ([kylef](https://github.com/kylef))

- Add logo [\#308](https://github.com/Mantle/Mantle/pull/308) ([jspahrsummers](https://github.com/jspahrsummers))

- Longer lived JSON adapters [\#278](https://github.com/Mantle/Mantle/pull/278) ([robb](https://github.com/robb))

## [1.5](https://github.com/Mantle/Mantle/tree/1.5) (2014-04-24)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.4.1...1.5)

**Implemented enhancements:**

- How can I map unknown JSON keys to an enum value? [\#303](https://github.com/Mantle/Mantle/issues/303)

- Improve console output of `mtl\_JSONArrayTransformerWithModelClass:` [\#288](https://github.com/Mantle/Mantle/issues/288)

- Map a property to multiple JSON key paths [\#263](https://github.com/Mantle/Mantle/issues/263)

- Exclude weak properties from equality checks etc. [\#204](https://github.com/Mantle/Mantle/issues/204)

**Fixed bugs:**

- JSON serialization should throw exceptions & errors if it couldn't find nominated fields in JSONKeyPathsByPropertyKey [\#293](https://github.com/Mantle/Mantle/issues/293)

**Closed issues:**

- JSONKeyPathsByPropertyKey: on MTLJSONSerializing could be @optional [\#296](https://github.com/Mantle/Mantle/issues/296)

- Key-based transformers inconsistency [\#291](https://github.com/Mantle/Mantle/issues/291)

- Mapping Core Data relationships onto Mantle Models very inconvenient due to NSSet and NSArray  mismatch [\#287](https://github.com/Mantle/Mantle/issues/287)

- Include path mentioned in README incorrect for archive builds [\#269](https://github.com/Mantle/Mantle/issues/269)

**Merged pull requests:**

- Fix null pointer dereference [\#317](https://github.com/Mantle/Mantle/pull/317) ([robb](https://github.com/robb))

- Fix crash bug when parsing JSONArray [\#316](https://github.com/Mantle/Mantle/pull/316) ([sojingle](https://github.com/sojingle))

- Made JSONKeyPathsByPropertyKey optional [\#312](https://github.com/Mantle/Mantle/pull/312) ([gamenerds](https://github.com/gamenerds))

- make mergeValuesForKeysFromModel: work with sub classes [\#311](https://github.com/Mantle/Mantle/pull/311) ([kilink](https://github.com/kilink))

- Remove MTLTestNotificationObserver [\#309](https://github.com/Mantle/Mantle/pull/309) ([robb](https://github.com/robb))

- Enum mapping default value [\#304](https://github.com/Mantle/Mantle/pull/304) ([paulyoung](https://github.com/paulyoung))

- Ignore AppCode's .idea folder [\#302](https://github.com/Mantle/Mantle/pull/302) ([robb](https://github.com/robb))

- Convenience functions for converting arrays of models to models and to JSON. [\#299](https://github.com/Mantle/Mantle/pull/299) ([paulthorsteinson](https://github.com/paulthorsteinson))

- CWE 121 vulnerability [\#295](https://github.com/Mantle/Mantle/pull/295) ([daveanderson](https://github.com/daveanderson))

- Throw an error if mappings don't match property keys [\#294](https://github.com/Mantle/Mantle/pull/294) ([robb](https://github.com/robb))

- Flatten dependencies [\#279](https://github.com/Mantle/Mantle/pull/279) ([robrix](https://github.com/robrix))

- Require every element along a JSON key path to be a NSDictionary [\#275](https://github.com/Mantle/Mantle/pull/275) ([robb](https://github.com/robb))

- Check if model is a placeholder before overriding existing CoreData properties [\#272](https://github.com/Mantle/Mantle/pull/272) ([bartvandendriessche](https://github.com/bartvandendriessche))

- Map properties to multiple JSON key paths [\#270](https://github.com/Mantle/Mantle/pull/270) ([robb](https://github.com/robb))

- Implicit validation [\#251](https://github.com/Mantle/Mantle/pull/251) ([robb](https://github.com/robb))

- Extract the MTLModel protocol [\#219](https://github.com/Mantle/Mantle/pull/219) ([robb](https://github.com/robb))

- Add storage behavior for property keys [\#210](https://github.com/Mantle/Mantle/pull/210) ([robb](https://github.com/robb))

## [1.4.1](https://github.com/Mantle/Mantle/tree/1.4.1) (2014-03-11)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.4...1.4.1)

**Implemented enhancements:**

- Automatic value transformers [\#147](https://github.com/Mantle/Mantle/issues/147)

**Fixed bugs:**

- MTLJSONAdapter modelOfClass: fails if array is present [\#257](https://github.com/Mantle/Mantle/issues/257)

**Closed issues:**

- MTLModel+NSCoding::decodeValueForKey does not provide enough information to debug exceptions [\#238](https://github.com/Mantle/Mantle/issues/238)

**Merged pull requests:**

- Bump xcconfigs for Xcode 5 backwards compatibility [\#267](https://github.com/Mantle/Mantle/pull/267) ([alanjrogers](https://github.com/alanjrogers))

- Keypath regression [\#266](https://github.com/Mantle/Mantle/pull/266) ([robb](https://github.com/robb))

- Fix keypath regression [\#265](https://github.com/Mantle/Mantle/pull/265) ([dcordero](https://github.com/dcordero))

- Add support for file URLs in MTLURLValueTransformerName [\#262](https://github.com/Mantle/Mantle/pull/262) ([mrh-is](https://github.com/mrh-is))

- Add ability to deep copy a MTLModel object [\#249](https://github.com/Mantle/Mantle/pull/249) ([sibljon](https://github.com/sibljon))

- Added array mapping transformer and refactored JSON array transformer  [\#248](https://github.com/Mantle/Mantle/pull/248) ([dcaunt](https://github.com/dcaunt))

- If we've added an NSNull for a nil key, and later encounter a keypath re... [\#246](https://github.com/Mantle/Mantle/pull/246) ([mchambers](https://github.com/mchambers))

- Added a function to only serialize given keys [\#245](https://github.com/Mantle/Mantle/pull/245) ([YasKuraishi](https://github.com/YasKuraishi))

- \[WIP\] Property types validation [\#242](https://github.com/Mantle/Mantle/pull/242) ([zats](https://github.com/zats))

- \[WIP\] Add array mapping value transformer [\#191](https://github.com/Mantle/Mantle/pull/191) ([dcaunt](https://github.com/dcaunt))

- Add implicit transformers [\#188](https://github.com/Mantle/Mantle/pull/188) ([robb](https://github.com/robb))

- \[WIP\] Add a cache for transformer objects. [\#112](https://github.com/Mantle/Mantle/pull/112) ([steipete](https://github.com/steipete))

## [1.4](https://github.com/Mantle/Mantle/tree/1.4) (2014-02-13)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.3.1...1.4)

**Implemented enhancements:**

- Add a array transformation convenience method to MTLJSONAdapter [\#176](https://github.com/Mantle/Mantle/issues/176)

**Fixed bugs:**

- Mantle-iOS is not building on Xcode 5.1  [\#221](https://github.com/Mantle/Mantle/issues/221)

- Properties declared in a protocol do not get serialized. [\#196](https://github.com/Mantle/Mantle/issues/196)

- Doesn't build for 64-bit iOS [\#178](https://github.com/Mantle/Mantle/issues/178)

- -initWithDictionary:errors: should be the designated initializer for MTLModel [\#172](https://github.com/Mantle/Mantle/issues/172)

- MTLManagedObjectAdapter -managedObjectFromModel:insertingIntoContext:error: does not pass errors up chain properly [\#165](https://github.com/Mantle/Mantle/issues/165)

**Closed issues:**

- How to implement more than 1 JSON model? [\#231](https://github.com/Mantle/Mantle/issues/231)

- `MTLJSONAdapter` <--\> `MTLManagedObjectAdapter` boolean quirks [\#226](https://github.com/Mantle/Mantle/issues/226)

- Float \(Numbers\) are serialized/deserialized with different values [\#213](https://github.com/Mantle/Mantle/issues/213)

- dictionaryValue does not 'print well' [\#208](https://github.com/Mantle/Mantle/issues/208)

- Move to a new org [\#200](https://github.com/Mantle/Mantle/issues/200)

- Never ending story/comparision [\#190](https://github.com/Mantle/Mantle/issues/190)

- -dictionaryValue ignores +JSONKeyPathsByPropertyKey [\#187](https://github.com/Mantle/Mantle/issues/187)

- Doesn't build in Xcode 5.0.1? [\#177](https://github.com/Mantle/Mantle/issues/177)

- Remove 1.x deprecations [\#171](https://github.com/Mantle/Mantle/issues/171)

- Crash in mtl\_JSONDictionaryTransformerWithModelClass: when running Tests [\#168](https://github.com/Mantle/Mantle/issues/168)

- Add an error handling mechanism to NSValueTransformer [\#152](https://github.com/Mantle/Mantle/issues/152)

- Revisit implicit JSON mapping [\#149](https://github.com/Mantle/Mantle/issues/149)

**Merged pull requests:**

- Log errors on encoding/decoding with the key name. [\#241](https://github.com/Mantle/Mantle/pull/241) ([dblock](https://github.com/dblock))

- Fix backwards compatibility for keys with value null [\#235](https://github.com/Mantle/Mantle/pull/235) ([dcordero](https://github.com/dcordero))

- Added support for deserializing into unrelated types. [\#233](https://github.com/Mantle/Mantle/pull/233) ([dblock](https://github.com/dblock))

- Asserting that an entity has a MOC [\#232](https://github.com/Mantle/Mantle/pull/232) ([notjosh](https://github.com/notjosh))

- Fix crash on invalid key path [\#230](https://github.com/Mantle/Mantle/pull/230) ([dcordero](https://github.com/dcordero))

- Removed variables that where causing compiler error. [\#228](https://github.com/Mantle/Mantle/pull/228) ([Goles](https://github.com/Goles))

- ++xcconfigs [\#227](https://github.com/Mantle/Mantle/pull/227) ([robb](https://github.com/robb))

- Fixed 'guarantee' typo [\#224](https://github.com/Mantle/Mantle/pull/224) ([eliperkins](https://github.com/eliperkins))

- fix recursive description call [\#222](https://github.com/Mantle/Mantle/pull/222) ([denis-kanonik](https://github.com/denis-kanonik))

- MTLManagedObjectAdapter: Fix a bug where errors are silently handled [\#220](https://github.com/Mantle/Mantle/pull/220) ([kylef](https://github.com/kylef))

- 2014, yo! [\#218](https://github.com/Mantle/Mantle/pull/218) ([dataxpress](https://github.com/dataxpress))

- Fix a crash when key is null in mtl\_valueMappingTransformer [\#212](https://github.com/Mantle/Mantle/pull/212) ([blueless](https://github.com/blueless))

- Very minor typo fix [\#211](https://github.com/Mantle/Mantle/pull/211) ([ColinEberhardt](https://github.com/ColinEberhardt))

- Fix/205 [\#206](https://github.com/Mantle/Mantle/pull/206) ([maxgoedjen](https://github.com/maxgoedjen))

- Expose -JSONKeyPathForKey: [\#199](https://github.com/Mantle/Mantle/pull/199) ([robb](https://github.com/robb))

- Fix a crash when receving something different than a NSDictionary [\#197](https://github.com/Mantle/Mantle/pull/197) ([dcordero](https://github.com/dcordero))

- Update dependencies for arm64 tests [\#192](https://github.com/Mantle/Mantle/pull/192) ([jspahrsummers](https://github.com/jspahrsummers))

- \[WIP\] Add default value for mtl\_valueMappingTransformer [\#189](https://github.com/Mantle/Mantle/pull/189) ([DAlOG](https://github.com/DAlOG))

- Include 64-bit build in iOS library [\#186](https://github.com/Mantle/Mantle/pull/186) ([bdolman](https://github.com/bdolman))

- Update README.md [\#184](https://github.com/Mantle/Mantle/pull/184) ([dismory](https://github.com/dismory))

- Value collection to relationship [\#183](https://github.com/Mantle/Mantle/pull/183) ([rex-remind101](https://github.com/rex-remind101))

- Build with xctool [\#182](https://github.com/Mantle/Mantle/pull/182) ([jspahrsummers](https://github.com/jspahrsummers))

- Remove RunUnitTests scripts [\#181](https://github.com/Mantle/Mantle/pull/181) ([jspahrsummers](https://github.com/jspahrsummers))

- Removed empty line [\#180](https://github.com/Mantle/Mantle/pull/180) ([dcaunt](https://github.com/dcaunt))

- Use the predefined mtl\_valueMappingTransformerWithDictionary in the README [\#179](https://github.com/Mantle/Mantle/pull/179) ([dcaunt](https://github.com/dcaunt))

- Add convenience method to MTLModel to transform JSON dictionaries [\#175](https://github.com/Mantle/Mantle/pull/175) ([lmcd](https://github.com/lmcd))

- Remove MTLJSONAdapter methods deprecated in 1.x [\#174](https://github.com/Mantle/Mantle/pull/174) ([robb](https://github.com/robb))

- Explicit mapping [\#170](https://github.com/Mantle/Mantle/pull/170) ([robb](https://github.com/robb))

- Explicit mapping [\#169](https://github.com/Mantle/Mantle/pull/169) ([robb](https://github.com/robb))

- Pipe error into tmpError when serializing child objects. [\#166](https://github.com/Mantle/Mantle/pull/166) ([maxgoedjen](https://github.com/maxgoedjen))

- Ensure that relationships are updated for an object matching a uniqueness constraint [\#163](https://github.com/Mantle/Mantle/pull/163) ([jilouc](https://github.com/jilouc))

- Improved error description and failure reason when the JSON dictionary is nil [\#161](https://github.com/Mantle/Mantle/pull/161) ([keithduncan](https://github.com/keithduncan))

- JSON dictionary error handling redux [\#160](https://github.com/Mantle/Mantle/pull/160) ([keithduncan](https://github.com/keithduncan))

- Adding MTLTransformerErrorHandling [\#153](https://github.com/Mantle/Mantle/pull/153) ([robb](https://github.com/robb))

- Added Error when the JSONDictionary received is nil [\#144](https://github.com/Mantle/Mantle/pull/144) ([dcordero](https://github.com/dcordero))

## [1.3.1](https://github.com/Mantle/Mantle/tree/1.3.1) (2013-10-10)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.3...1.3.1)

**Implemented enhancements:**

- Opt-out of implicit property mapping per-class [\#138](https://github.com/Mantle/Mantle/issues/138)

- Include version number in header [\#119](https://github.com/Mantle/Mantle/issues/119)

- Is it possible to update a NSManagedObject? [\#114](https://github.com/Mantle/Mantle/issues/114)

- MTLModel subclass encodeWithCoder -\> unrecognized selector sent to instance [\#93](https://github.com/Mantle/Mantle/issues/93)

**Fixed bugs:**

- The File "\*.xccconfig" couldn't be opened because it's path couldn't be resolved. It may be missing. [\#84](https://github.com/Mantle/Mantle/issues/84)

**Merged pull requests:**

- OS X static library [\#158](https://github.com/Mantle/Mantle/pull/158) ([jspahrsummers](https://github.com/jspahrsummers))

- Adding documentation for -isEqual and -description [\#146](https://github.com/Mantle/Mantle/pull/146) ([robb](https://github.com/robb))

- Optionally opt out of implicit mappings [\#143](https://github.com/Mantle/Mantle/pull/143) ([robb](https://github.com/robb))

- Add installation guide to README [\#139](https://github.com/Mantle/Mantle/pull/139) ([akashivskyy](https://github.com/akashivskyy))

- Make +JSONKeyPathsByPropertyKey optional [\#137](https://github.com/Mantle/Mantle/pull/137) ([ryanmaxwell](https://github.com/ryanmaxwell))

- Added awakeFromModel for purpose of notifying receiver to prepare itself... [\#136](https://github.com/Mantle/Mantle/pull/136) ([mpurland](https://github.com/mpurland))

- Add transformer for transforming between the keys and objects of a dictionary [\#135](https://github.com/Mantle/Mantle/pull/135) ([rastersize](https://github.com/rastersize))

- Change "adaptor" to "adapter" in the documentation [\#134](https://github.com/Mantle/Mantle/pull/134) ([akashivskyy](https://github.com/akashivskyy))

- Adding subclassing notes to README [\#133](https://github.com/Mantle/Mantle/pull/133) ([robb](https://github.com/robb))

- Prevent deleting `nil` in MTLManagedObjectAdapter [\#120](https://github.com/Mantle/Mantle/pull/120) ([robb](https://github.com/robb))

## [1.3](https://github.com/Mantle/Mantle/tree/1.3) (2013-09-06)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.2...1.3)

**Implemented enhancements:**

- Convert null values to NSNull using the array transformer [\#107](https://github.com/Mantle/Mantle/issues/107)

**Closed issues:**

- Cannot get associations to work [\#132](https://github.com/Mantle/Mantle/issues/132)

- MTLValidateAndSetValue crashes on nil value [\#121](https://github.com/Mantle/Mantle/issues/121)

- More pre-defined NSValueTransformers? [\#115](https://github.com/Mantle/Mantle/issues/115)

**Merged pull requests:**

- Change submodule URLs to HTTPS \(from Git\) to avoid firewalls that block ... [\#130](https://github.com/Mantle/Mantle/pull/130) ([orj](https://github.com/orj))

- Expose MTLReversibleValueTransformer interface to make it easier to subclass. [\#129](https://github.com/Mantle/Mantle/pull/129) ([joshvera](https://github.com/joshvera))

- Improving documentation on JSON serialization [\#128](https://github.com/Mantle/Mantle/pull/128) ([robb](https://github.com/robb))

- Remove inclusion of config.h fixes \#124 [\#126](https://github.com/Mantle/Mantle/pull/126) ([jchatard](https://github.com/jchatard))

- Adding null support to array transformers [\#125](https://github.com/Mantle/Mantle/pull/125) ([robb](https://github.com/robb))

- Remove useless InfoPlist.strings files [\#123](https://github.com/Mantle/Mantle/pull/123) ([akashivskyy](https://github.com/akashivskyy))

- Remove libextobjc usage. [\#111](https://github.com/Mantle/Mantle/pull/111) ([steipete](https://github.com/steipete))

- Remove mtl\_firstObject, declare header so we can already use it in Xcode 4 [\#110](https://github.com/Mantle/Mantle/pull/110) ([steipete](https://github.com/steipete))

- Add test to show URL Transformer bug [\#109](https://github.com/Mantle/Mantle/pull/109) ([mattyohe](https://github.com/mattyohe))

## [1.2](https://github.com/Mantle/Mantle/tree/1.2) (2013-07-18)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.1.2...1.2)

**Implemented enhancements:**

- Invert a value transformer [\#91](https://github.com/Mantle/Mantle/issues/91)

**Closed issues:**

- Returning a C type from a transformer [\#105](https://github.com/Mantle/Mantle/issues/105)

- 1.1.1 not in CocoaPods [\#100](https://github.com/Mantle/Mantle/issues/100)

**Merged pull requests:**

- Remove crash when parsing a JSON array with \*null\* items in it [\#106](https://github.com/Mantle/Mantle/pull/106) ([ursachec](https://github.com/ursachec))

- Adding validation hooks to MTLModel [\#104](https://github.com/Mantle/Mantle/pull/104) ([robb](https://github.com/robb))

- Explicitly validate default values [\#103](https://github.com/Mantle/Mantle/pull/103) ([robb](https://github.com/robb))

- Ability to have alternative JSON keypaths for a model property [\#102](https://github.com/Mantle/Mantle/pull/102) ([cloudkite](https://github.com/cloudkite))

## [1.1.2](https://github.com/Mantle/Mantle/tree/1.1.2) (2013-06-25)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.1.1...1.1.2)

**Merged pull requests:**

- Fix duplicate interface error when using Mantle with CocoaPods [\#99](https://github.com/Mantle/Mantle/pull/99) ([lmcd](https://github.com/lmcd))

## [1.1.1](https://github.com/Mantle/Mantle/tree/1.1.1) (2013-06-25)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.1...1.1.1)

**Merged pull requests:**

- Replace libextobjc submodule with a subtree and namespace its symbols [\#98](https://github.com/Mantle/Mantle/pull/98) ([jspahrsummers](https://github.com/jspahrsummers))

- Update xcode [\#97](https://github.com/Mantle/Mantle/pull/97) ([joshaber](https://github.com/joshaber))

- Ignore NSNull dictionary values [\#96](https://github.com/Mantle/Mantle/pull/96) ([alin3994](https://github.com/alin3994))

## [1.1](https://github.com/Mantle/Mantle/tree/1.1) (2013-05-21)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.0.1...1.1)

**Implemented enhancements:**

- Make it easy to create class clusters for models and view models [\#16](https://github.com/Mantle/Mantle/issues/16)

**Merged pull requests:**

- Added NSValueTransformer.mtl\_invertedTransformer [\#92](https://github.com/Mantle/Mantle/pull/92) ([jspahrsummers](https://github.com/jspahrsummers))

- Core Data adapter [\#87](https://github.com/Mantle/Mantle/pull/87) ([jspahrsummers](https://github.com/jspahrsummers))

## [1.0.1](https://github.com/Mantle/Mantle/tree/1.0.1) (2013-04-26)

[Full Changelog](https://github.com/Mantle/Mantle/compare/1.0...1.0.1)

**Closed issues:**

- NSArray+MTLManipulationAdditions.m:14:26: Expected method to read array element not found on object of type 'NSArray \*' [\#85](https://github.com/Mantle/Mantle/issues/85)

**Merged pull requests:**

- Mention the base SDK and deployment targets [\#86](https://github.com/Mantle/Mantle/pull/86) ([jspahrsummers](https://github.com/jspahrsummers))

- Failing gracefully for inconsistent APIs [\#82](https://github.com/Mantle/Mantle/pull/82) ([myell0w](https://github.com/myell0w))

- Optimize selector building [\#81](https://github.com/Mantle/Mantle/pull/81) ([jspahrsummers](https://github.com/jspahrsummers))

- Fixing Duplicate interface definition errors when using via cocoapods [\#80](https://github.com/Mantle/Mantle/pull/80) ([JaviSoto](https://github.com/JaviSoto))

## [1.0](https://github.com/Mantle/Mantle/tree/1.0) (2013-03-06)

[Full Changelog](https://github.com/Mantle/Mantle/compare/0.4.1...1.0)

**Merged pull requests:**

- Replace 'assigneeLogin' field with 'assignee' to demo nested models [\#78](https://github.com/Mantle/Mantle/pull/78) ([jspahrsummers](https://github.com/jspahrsummers))

- Remove higher order functions and weak NSNotificationCenter observers [\#77](https://github.com/Mantle/Mantle/pull/77) ([jspahrsummers](https://github.com/jspahrsummers))

## [0.4.1](https://github.com/Mantle/Mantle/tree/0.4.1) (2013-03-03)

[Full Changelog](https://github.com/Mantle/Mantle/compare/0.4...0.4.1)

**Implemented enhancements:**

- Support error reporting from -initWithDictionary: [\#66](https://github.com/Mantle/Mantle/issues/66)

**Merged pull requests:**

- Corrected method name \(+supportsSecureCoding\) [\#79](https://github.com/Mantle/Mantle/pull/79) ([indragiek](https://github.com/indragiek))

## [0.4](https://github.com/Mantle/Mantle/tree/0.4) (2013-02-27)

[Full Changelog](https://github.com/Mantle/Mantle/compare/0.3.1...0.4)

**Implemented enhancements:**

- Add support for NSSecureCoding [\#53](https://github.com/Mantle/Mantle/issues/53)

**Fixed bugs:**

- Secure coding conformance requires implementation of -initWithCoder/-encodeWithCoder: [\#74](https://github.com/Mantle/Mantle/issues/74)

**Merged pull requests:**

- Fix subclasses having to override -initWithCoder: for secure coding [\#75](https://github.com/Mantle/Mantle/pull/75) ([jspahrsummers](https://github.com/jspahrsummers))

- Add jspahrsummers/objc-build-scripts [\#73](https://github.com/Mantle/Mantle/pull/73) ([jspahrsummers](https://github.com/jspahrsummers))

- Allow model classes to report initialization errors [\#67](https://github.com/Mantle/Mantle/pull/67) ([jspahrsummers](https://github.com/jspahrsummers))

## [0.3.1](https://github.com/Mantle/Mantle/tree/0.3.1) (2013-02-25)

[Full Changelog](https://github.com/Mantle/Mantle/compare/0.3...0.3.1)

**Implemented enhancements:**

- Exclude properties from being part of the external representation ? [\#48](https://github.com/Mantle/Mantle/issues/48)

- Handling Model Relationship [\#42](https://github.com/Mantle/Mantle/issues/42)

**Fixed bugs:**

- GHIssue Example incorrect for 0.3 API [\#68](https://github.com/Mantle/Mantle/issues/68)

**Merged pull requests:**

- Update README.md [\#72](https://github.com/Mantle/Mantle/pull/72) ([YuAo](https://github.com/YuAo))

- Secure coding fixes [\#71](https://github.com/Mantle/Mantle/pull/71) ([indragiek](https://github.com/indragiek))

- <NSSecureCoding\> support [\#70](https://github.com/Mantle/Mantle/pull/70) ([jspahrsummers](https://github.com/jspahrsummers))

- Remove call to MTLModel method that no longer exists [\#69](https://github.com/Mantle/Mantle/pull/69) ([jspahrsummers](https://github.com/jspahrsummers))

## [0.3](https://github.com/Mantle/Mantle/tree/0.3) (2013-02-15)

[Full Changelog](https://github.com/Mantle/Mantle/compare/0.2.3...0.3)

**Closed issues:**

- Facebook sharing is out of date [\#62](https://github.com/Mantle/Mantle/issues/62)

- Clicking on any scoreboard currently causes a crash [\#61](https://github.com/Mantle/Mantle/issues/61)

**Merged pull requests:**

- Model adapters [\#64](https://github.com/Mantle/Mantle/pull/64) ([jspahrsummers](https://github.com/jspahrsummers))

- Remove in-repo podspec [\#63](https://github.com/Mantle/Mantle/pull/63) ([jspahrsummers](https://github.com/jspahrsummers))

- NSSecureCoding implementation [\#60](https://github.com/Mantle/Mantle/pull/60) ([indragiek](https://github.com/indragiek))

- New MTLModel interface to support multiple external representations [\#52](https://github.com/Mantle/Mantle/pull/52) ([jspahrsummers](https://github.com/jspahrsummers))

## [0.2.3](https://github.com/Mantle/Mantle/tree/0.2.3) (2013-01-10)

[Full Changelog](https://github.com/Mantle/Mantle/compare/0.2.2...0.2.3)

**Implemented enhancements:**

- Lightweight Vs. Heavyweight [\#39](https://github.com/Mantle/Mantle/issues/39)

**Closed issues:**

- Exclude properties from being considered regarding equality [\#57](https://github.com/Mantle/Mantle/issues/57)

- Mantle and mutable properties \(specifically arrays\) [\#51](https://github.com/Mantle/Mantle/issues/51)

- Crash on Release build [\#45](https://github.com/Mantle/Mantle/issues/45)

**Merged pull requests:**

- Added -mtl\_anyObjectPassingTest: [\#59](https://github.com/Mantle/Mantle/pull/59) ([joshaber](https://github.com/joshaber))

- Xcode ++ and bump expecta, specta and libextobjc. [\#58](https://github.com/Mantle/Mantle/pull/58) ([alanjrogers](https://github.com/alanjrogers))

- ++xcconfigs, simplify project settings a bit [\#56](https://github.com/Mantle/Mantle/pull/56) ([jspahrsummers](https://github.com/jspahrsummers))

- change location of headers for iOS static lib target [\#55](https://github.com/Mantle/Mantle/pull/55) ([pizthewiz](https://github.com/pizthewiz))

- Remove talk of Core Data concurrency from the README [\#54](https://github.com/Mantle/Mantle/pull/54) ([jspahrsummers](https://github.com/jspahrsummers))

- Ignore Desktop Services attribute files [\#50](https://github.com/Mantle/Mantle/pull/50) ([pizthewiz](https://github.com/pizthewiz))

- Add method to specify desired property keys in external representation [\#49](https://github.com/Mantle/Mantle/pull/49) ([pizthewiz](https://github.com/pizthewiz))

- Use -ObjC instead of -all\_load for linking unit tests [\#47](https://github.com/Mantle/Mantle/pull/47) ([jspahrsummers](https://github.com/jspahrsummers))

## [0.2.2](https://github.com/Mantle/Mantle/tree/0.2.2) (2012-11-13)

[Full Changelog](https://github.com/Mantle/Mantle/compare/0.2.1...0.2.2)

**Implemented enhancements:**

- Add MTLEqualObjects\(\) [\#33](https://github.com/Mantle/Mantle/issues/33)

- Clarify in the README that Mantle doesn't provide persistence [\#29](https://github.com/Mantle/Mantle/issues/29)

- Convert the Mantle blog post into a better README [\#26](https://github.com/Mantle/Mantle/issues/26)

- Add a protocol to manipulate all collections as sequences [\#1](https://github.com/Mantle/Mantle/issues/1)

**Fixed bugs:**

- MTLValueTransformer can't return NSUInteger, only a value object pointer [\#37](https://github.com/Mantle/Mantle/issues/37)

**Closed issues:**

- MTLModel - propertyKeys - not always freeing attributes [\#40](https://github.com/Mantle/Mantle/issues/40)

**Merged pull requests:**

- First pass at a CONTRIBUTING file [\#43](https://github.com/Mantle/Mantle/pull/43) ([jspahrsummers](https://github.com/jspahrsummers))

- In +propertyKeys, make sure to always free 'attributes' [\#41](https://github.com/Mantle/Mantle/pull/41) ([jspahrsummers](https://github.com/jspahrsummers))

- Fix incorrect transformer code in README [\#38](https://github.com/Mantle/Mantle/pull/38) ([jspahrsummers](https://github.com/jspahrsummers))

- Better README [\#36](https://github.com/Mantle/Mantle/pull/36) ([jspahrsummers](https://github.com/jspahrsummers))

- NSValueTransformer for boolean NSNumbers [\#35](https://github.com/Mantle/Mantle/pull/35) ([terinjokes](https://github.com/terinjokes))

- Adding MTLEqualObjects function [\#34](https://github.com/Mantle/Mantle/pull/34) ([joshvera](https://github.com/joshvera))

- Fix podspec again [\#32](https://github.com/Mantle/Mantle/pull/32) ([mattyohe](https://github.com/mattyohe))

- Mantel should only include utilized subspecs of libextobjc [\#31](https://github.com/Mantle/Mantle/pull/31) ([mattyohe](https://github.com/mattyohe))

- Add armv7s as a valid architecture [\#30](https://github.com/Mantle/Mantle/pull/30) ([joshvera](https://github.com/joshvera))

## [0.2.1](https://github.com/Mantle/Mantle/tree/0.2.1) (2012-10-23)

[Full Changelog](https://github.com/Mantle/Mantle/compare/0.2...0.2.1)

**Closed issues:**

- Does Mantle handle any persistence? [\#28](https://github.com/Mantle/Mantle/issues/28)

**Merged pull requests:**

- Adds CocoaPods support. [\#27](https://github.com/Mantle/Mantle/pull/27) ([chakrit](https://github.com/chakrit))

## [0.2](https://github.com/Mantle/Mantle/tree/0.2) (2012-10-22)

[Full Changelog](https://github.com/Mantle/Mantle/compare/0.1...0.2)

**Merged pull requests:**

- Purge the heathen geometry additions [\#25](https://github.com/Mantle/Mantle/pull/25) ([jspahrsummers](https://github.com/jspahrsummers))

- Fix Link to MTLModel.h [\#24](https://github.com/Mantle/Mantle/pull/24) ([travisjeffery](https://github.com/travisjeffery))

## [0.1](https://github.com/Mantle/Mantle/tree/0.1) (2012-10-22)

**Implemented enhancements:**

- New name [\#5](https://github.com/Mantle/Mantle/issues/5)

**Merged pull requests:**

- Add an autorelease pool to +load [\#23](https://github.com/Mantle/Mantle/pull/23) ([jspahrsummers](https://github.com/jspahrsummers))

- Extend rect division functions to allow properties [\#22](https://github.com/Mantle/Mantle/pull/22) ([jspahrsummers](https://github.com/jspahrsummers))

- Added CGGeometry+MTLConvenienceAdditions [\#21](https://github.com/Mantle/Mantle/pull/21) ([jspahrsummers](https://github.com/jspahrsummers))

- More typing [\#20](https://github.com/Mantle/Mantle/pull/20) ([joshaber](https://github.com/joshaber))

- Fix +propertyKeys to not include readonly properties without ivars [\#19](https://github.com/Mantle/Mantle/pull/19) ([jspahrsummers](https://github.com/jspahrsummers))

- Add an assertion to -mtl\_addWeakObserver: [\#18](https://github.com/Mantle/Mantle/pull/18) ([alanjrogers](https://github.com/alanjrogers))

- Update -mtl\_addWeakObserver: to allow a selector that doesn't take any arguments [\#17](https://github.com/Mantle/Mantle/pull/17) ([alanjrogers](https://github.com/alanjrogers))

- Added support for key paths in external representations [\#15](https://github.com/Mantle/Mantle/pull/15) ([jspahrsummers](https://github.com/jspahrsummers))

- Added -mtl\_dictionaryByRemovingEntriesWithKeys: [\#14](https://github.com/Mantle/Mantle/pull/14) ([joshaber](https://github.com/joshaber))

- Project updates for Xcode 4.5 [\#13](https://github.com/Mantle/Mantle/pull/13) ([joshaber](https://github.com/joshaber))

- Factory methods to create transformers for MTLModel <-\> external representation [\#12](https://github.com/Mantle/Mantle/pull/12) ([jspahrsummers](https://github.com/jspahrsummers))

- Added an NSNotificationCenter extension for weak references [\#11](https://github.com/Mantle/Mantle/pull/11) ([jspahrsummers](https://github.com/jspahrsummers))

- Added -\[NSDictionary mtl\_dictionaryByAddingEntriesFromDictionary:\] [\#10](https://github.com/Mantle/Mantle/pull/10) ([jspahrsummers](https://github.com/jspahrsummers))

- Array manipulation methods should always return immutable NSArrays [\#9](https://github.com/Mantle/Mantle/pull/9) ([jspahrsummers](https://github.com/jspahrsummers))

- Better, more informational README [\#8](https://github.com/Mantle/Mantle/pull/8) ([jspahrsummers](https://github.com/jspahrsummers))

- Refactored MTLModel to be mutable instead of immutable [\#7](https://github.com/Mantle/Mantle/pull/7) ([jspahrsummers](https://github.com/jspahrsummers))

- Project rename [\#6](https://github.com/Mantle/Mantle/pull/6) ([jspahrsummers](https://github.com/jspahrsummers))

- Some convenience methods for creating new arrays [\#4](https://github.com/Mantle/Mantle/pull/4) ([joshaber](https://github.com/joshaber))

- Added a reusable URL value transformer [\#3](https://github.com/Mantle/Mantle/pull/3) ([jspahrsummers](https://github.com/jspahrsummers))

- MAVModel [\#2](https://github.com/Mantle/Mantle/pull/2) ([jspahrsummers](https://github.com/jspahrsummers))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*