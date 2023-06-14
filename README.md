# Automerge Swift Additions

[![codecov](https://codecov.io/gh/heckj/AutomergeSwiftAdditions/branch/main/graph/badge.svg?token=D592XNTYBM)](https://codecov.io/gh/heckj/AutomergeSwiftAdditions)

![sunburst graph of code coverage](https://codecov.io/gh/heckj/AutomergeSwiftAdditions/branch/main/graphs/sunburst.svg?token=D592XNTYBM)

---

Explorations in extending [Automerge-swifter](http://github.com/automerge/automerge-swifter/) to be easier to use within a SwiftUI app context.

I'd previously been doing this work in [AMTravelNotes](https://github.com/heckj/AMTravelNotes) as a sample app.
As it turns out, Xcode is worse than useless at running tests when the hosting application is a UIDocument or NSDocument based app.
Every time you invoke a test to see overall coverage, the apps launch and hang - which in turn hangs Xcode from doing any further testing.

Most of the code within this repository is exploratory - use utterly at your own risk.
Anything that seems to be effective and useful I am intending to propose for merging into Automerge Swift language project: `Automerge-swifter`.
At the moment, it uses code beyond the current release, and as such has a local reference dependency.
This expects the Automerge-swifter project at the relevant branch to be checked out locally and in parallel with this repository.


Punchlist:

- [x] establish a Text type to hold strings that are meant to be collaborative (Text nodes in Automerge)
  - [x] bind/capture Text type in encoding to establish appropriate node
  - [x] update encoder to compare and update Text node values with diff structure
- [x] test text encoding variations - insert, delete, mixes - for correct results

- [x] measure (and track) code coverage
  - [x] expand code coverage for encoding - corner cases
  - [x] encoder to 80% with failure cases
  - [x] lookup/schema creation to 80% with failure cases

- [x] expand strategy to allow for strictly type checking when encoding single-value scalar values

- [x] strip out encoder duplicate structure that's created but not needed
  - [x] check performance impact for removing that extra stuff

- [x] establish decoder
  - [x] capture and override decoding Text, Data, Date, and Counter
- [x] expand encoder to allow "encode at" to aim within the schema
- [x] expand decoder to allow "decode from" to select within the schema to decode

- [x] review ScalarValueRepresentable - do we need it to exist with the encoder?
- [ ] test SwiftUI binding concept - see what making dozens of updates to a ScalarValue does to doc size
- [ ] add read-only, auto-generated UUID into Document to identify it from compatriots
- [ ] CBOR encode the document with the UUID and the Automerge "data" from a save for the document format
  - [ ] enabling matching decode - PotentCodables supports CBOR encoding






