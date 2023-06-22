# Automerge-based App Sync Use Case

## Setup

An original Document is started on one device (iPad), starts updating data.
The sync at this point is all file-based - you get everything, and the unique file indicates completely separate instances of the document.

The iPad app starts broadcasting "I'm open to active collaboration" (interactive/live style sync updates), and an iPhone app joins in.
It syncs to get a replica of the document, and as the collaboration session continues, updates are shared freely between the two.

The iPhone app has to hop on a plane, so the live-collaborative session ends, but the iPhone app has it's own copy that is up to date with the point of the last collaborative sync.
The owner of the iPhone reviews the work on the plane, and makes a few updates here and there, intending to sync it later when there's connectivity.

## Reconnect with Live Sync updates

The two devices later come back together, and want to resume the collaborative live-update syncing and editing experience.
However, in the mean time, the iPad app has made new documents, and collaboratively edited some of those documents with other users as well.
The app has a collection of possible documents "on disk", all named files.

Before resuming syncing, the user of the iPad app needs to know which file to open and start collaboratively sharing with the iPhone app.
The application would like to verify that these documents share a common history before resuming the syncing, updating both documents, to avoid the scenario where IF the documents don't share a history, the merging is far less obviously deterministic - and "one side wins", potentially loosing history for either the iPad or iPhone app depending on who "won" the sync.

What the app would like to do is provide feedback to the user of the iPhone and iPad apps that the documents _don't_ share a common history if that's the case, rather than just "syncing and doing it's best" with the potentially upsetting side effects.

## Reconnect with offline updates

The other reconnect and sync up scenario starts with "ye olde email", or some equivalent sharing of a separate file that's been updated and changed, but it otherwise in a static format (not backed by an active application that can sync and determine changes).

The same base desire exists - the person wants to read in the file and merge any changes, but _only_ if the files share a common ancestry.

With the Automerge API as it stands today, one application would need to run, loading and comparing the two documents to determine if there's common history before setting up a sync state and creating updates from the incoming document to update the local document.
Once successful (if successful), then the incoming document could potentially be discarded, as all updates would be included in the original document.

## Document Identifier for shared history

The quick and dirty obvious choice to solve this is to have some unique identifier that is created when a new document is established, and rides along with then document is cloned - either by sharing the persistent file on disk, or by an initial syncing when there's no other state at the receiving end.

In any case, something exposed from the API that shares a stable, unique identifier that can be compared to know there's a common ancestor would be the desired end goal from my perspective. Ideally, this identifier could be determined without having to load an existing document entirely into memory. 

Using a file name on a file system is a non-starter, as that's not a stable identifier, being easily updated and changed.
Right now the options are:

- Wrap an Automerge document in an enclosing binary envelope that includes an identifier; in which case the collaborating apps need to use the same mechanism outside of the Automerge API to propogate and preserve the Id for each document. (I believe this is the technique that's used in `automerge-repo`, wrapping the Automerge doc data into a wrapper using CBOR that includes a unique identifier.)
- Embed an identifier into the automerge document right after the initial "new document" state, and specifically check for conflicts on
that "special location" with the Automerge document to know if a conflicting sync has occured, or to have app-specific knowledge to read that Identifier and include it with a sync state message to allow the App to prevent accidentally merging documents without a shared common history.
