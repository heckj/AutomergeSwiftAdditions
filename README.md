# Automerge Swift Additions

Explorations in extending [Automerge-swifter](http://github.com/automerge/automerge-swifter/) to be easier to use within a SwiftUI app context.

I'd previously been doing this work in [AMTravelNotes](https://github.com/heckj/AMTravelNotes) as a sample app.
As it turns out, Xcode is worse than useless at running tests when the hosting application is a UIDocument or NSDocument based app.
Every time you invoke a test to see overall coverage, the apps launch and hang - which in turn hangs Xcode from doing any further testing.

Most of the code within this repository is exploratory - use utterly at your own risk. 
Anything that seems to be effective and useful I am intending to propose for merging into Automerge Swift language project: `Automerge-swifter`.
At the moment, it uses code beyond the current release, and as such has a local reference dependency. 
This expects the Automerge-swifter project at the relevant branch to be checked out locally and in parallel with this repository.
