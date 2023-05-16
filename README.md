# AutomergeSwiftAdditions

Explorations in extending [Automerge-swifter](http://github.com/automerge/automerge-swifter/pulls) to be easier to use within a SwiftUI app context.

I'd previously been doing this work in [AMTravelNotes](https://github.com/heckj/AMTravelNotes) as a sample app.
As it turns out, Xcode is worse than useless at running tests when the hosting application is a UIDocument or NSDocument based app.
Every time you invoke a test to see overall coverage, the apps launch and hang - which in turn hangs Xcode from doing any further testing.

