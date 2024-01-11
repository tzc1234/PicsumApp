# PicsumApp
## Practice the learnings from iOS Lead Essentials online course.

## Retrospective
### Async/await in unit test
Pros: The async functions work really well in unit tests marked with keyword `async`, seamlessly just like testing sync functions.
When compare with completion handler, async function is easier to reason what's going on, also avoid a callback hell.

Cons: Testing the bridging part between the sync world and async world is a bit messy.
`Task` must be used for bridging (especially in UIKit). When tests involved `Task`, I've to call `task.value` manually to complete the `Task`.
It's quite impactful to the production code, I must expose all references of the `Task` for testing purpose ONLY.
Also, I've encountered a situation of completing ONE `Task` does also complete other pending `Tasks`, this behaviour is quite counter-intuitive for me.
In completion handlers(closure), they will complete in order if tests by `Stub` or I can even tweak the order of completions by recording them at first.
Because of this, I would prefer completion handler more.

### SwiftData
A easier, handier API available in iOS 17 compare with CoreData, in my opinion.
Overall is good but not mature yet, for example I can't use `URL` for `predicate`, I've to convert to `String` before using at the moment.
Also, when instantiating more than one `ModelContainer` with same `URL` upfront, 
`Error Domain=NSCocoaErrorDomain Code=134020 "The model configuration used to open the store is incompatible with the one that was used to create the store.` will occur.
This is annoying when I was doing integration tests.

### Extract async logic from view model to adapter
I find that it is easier to understand the code after separating these concerns to different components. 
View models become only care about bindings, emit states to the UI, very lightweight. And the dirty async code is all handled in an adapter.
However, the trad-off is I have to maintain more components (adapters), and the communication from the UI to remote service is not that directly any more.

Before: `UI` -> `view model` -> `remote service` response data back -> `view model` through bindings -> `UI`.

Now: `UI` -> `adapter` -> `remote service` response data back -> `adapter` -> `view model` through bindings -> `UI`.

The complexity is obviously increased, harder to reason.

### About preview
In iOS 17, UIKit can utilize preview now as SwiftUI. However, I've tried preview for `PhotoListViewController`, it does not work properly.
The `UICollectionViewDiffableDataSource` is not running in preview, no collection view cell shown, I have no idea of this.
Therefore, I decide not to use preview at the moment.

## Screenshot
<img src="https://github.com/tzc1234/PicsumApp/blob/main/Screenshots/preview.png" alt="preview" width="256" height="554"/>

## Frameworks
1. Async/await
2. URLSession for [Picsum API](https://picsum.photos/)
3. ~~Core Data~~ SwiftData for image data caching
4. UIKit
5. XCTest

## Goals to achieve
1. Follow SOLID principles
2. Fully adopt TDD
3. Use of dependency injection
4. Refactor from MVC to MVVM, safeguard by tests
5. Compose all the components in the composition root (SceneDelegate)
6. Make use of design patterns: adapter, composite and decorator
7. Attempt to do better on naming