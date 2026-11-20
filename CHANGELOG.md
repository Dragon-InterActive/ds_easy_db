## 1.1.1

* Fixed: `MockStreamDatabase.watchQuery` with a filter returned no results
  after the first write (filter values were compared as strings).
* Fixed: `MockStreamDatabase` emitted twice per write to unfiltered queries.
* `MockStreamDatabase`: every listener now receives the current value on
  subscribe; subscribing no longer replays an event to existing listeners.
* `MockDatabase` / `MockStreamDatabase`: reads return copies; `getAll` and
  `watchAll` return `null` for an empty collection, as documented.
* `query` / `watchQuery` results now include the document id as `id`
  (a document's own `id` field is kept).
* Documentation fixes (`configure` parameters are optional, null-safe examples).

## 1.1.0

* Added Slot cache
* extended README.md

## 1.0.2

* Added MockStreamDatabase for testing streaming databases
* Made configure() parameters optional (not all repositories required)
* Fixed: MockDatabase cannot be used for stream parameter

## 1.0.1

* Added dartdoc comments to public API
* Added example documentation

## 1.0.0

* Initial release of ds_easy_db
* Unified database abstraction layer for Flutter
* Support for multiple storage backends
* MockDatabase for testing included
