# PicsumApp
## Practice the learnings from iOS Lead Essentials online course.

## Retrospective
### TDD on SwiftUI
Implementing the SwiftUI UI views themselves is easy, not a problem.:) However, adopting TDD on it is quite challenging. 
I've to utilise [ViewInspector](https://github.com/nalexn/ViewInspector) to enable the testability of SwiftUI components, this takes time to learn, try and practice, for example, `@State variable` can't be accessed outside the View, it will trigger purple warning from Xcode.
This limitation made me decide not to use `@State variable` during the development. Not even counting on the unpredictable re-initialisation of SwiftUI view, really time consuming to debug.
Although the solution is not perfect yet (`ViewInspector` does not 100% support all SwiftUI's API.), it can be proved that writing unit/integration tests for SwiftUI is possible. I really appreciate the efforts from the team of `ViewInspector`, unlocking the ability to do TDD for SwiftUI. Thanks!

### Async/await in unit test
Pros: The async functions work really well in unit tests marked with keyword `async`, seamlessly just like testing sync functions.
When compared with completion handlers, async functions are easier to reason about what's going on, and also avoid a callback hell.

Cons: Testing the bridging part between the sync world and async world is a bit messy.
`Task` must be used for bridging (especially in UIKit). When tests involve `Task`, I've to call `task.value` manually to complete the `Task`.
It's quite impactful to the production code, I must expose all references of the `Task` for testing purposes ONLY.
Also, I've encountered a situation where completing ONE `Task` does also complete other pending `Tasks`, this behaviour is quite counter-intuitive for me.
In completion handlers(closure), they will complete in order if they are tested by `Stub` or I can even tweak the order of completions by recording them at first.
Because of this, I would prefer completion handlers more.

### SwiftData
An easier, handier API available in iOS 17 compared with CoreData, in my opinion.
Overall it is good but not mature yet, for example I can't use `URL` for `predicate`, I've to convert to `String` before using at the moment.
Also, when instantiating more than one `ModelContainer` with same `URL` upfront, 
`Error Domain=NSCocoaErrorDomain Code=134020 "The model configuration used to open the store is incompatible with the one that was used to create the store.` will occur.
This was annoying when I was doing integration tests.

Benefiting from dependency injection/clean architecture, I can easily switch frameworks from `CoreData` to `SwiftData`. 
Changing an implementation of an `ImageDataStore` is not much effort when backed by automated tests, ensuring the whole code base works properly.

Before: `LocalImageDataLoader` use -> `<ImageDataStore>` <- implement `CoreDataImageDataStore`

Now: `LocalImageDataLoader` use -> `<ImageDataStore>` <- implement `SwiftDataImageDataStore`

### Extract async logic from view model to adapter
I find that it is easier to understand the code after separating these concerns to different components. 
View models only care about bindings, emit states to the UI, and are very lightweight. The dirty async code is all handled in an adapter.
However, the trade-off is I have to maintain more components (adapters), and the communication from the UI to remote service is not that direct any more.

Before: `UI` -> `view model` -> `remote service` response data back -> `view model` through bindings -> `UI`.

Now: `UI` -> `adapter` -> `remote service` response data back -> `adapter` -> `view model` through bindings -> `UI`.

The complexity is obviously increased, harder to reason.

### About preview
In iOS 17, UIKit can utilise preview now as SwiftUI. However, I've tried a preview for `PhotoListViewController`, but it does not work properly.
The `UICollectionViewDiffableDataSource` is not running in preview, no collection view cell shown, I have no idea of this.
Therefore, I decided not to use preview at the moment.

***SwiftUI views are all utilised with previews. No reason not to use previews for SwiftUI views!***


## Screenshots
<img src="https://github.com/tzc1234/PicsumApp/blob/main/Screenshots/preview.png" alt="preview" width="256" height="554"/> <img src="https://github.com/tzc1234/PicsumApp/blob/main/Screenshots/preview2.png" alt="preview2" width="256" height="554"/>

## Frameworks
1. Async/await
2. URLSession for [Picsum API](https://picsum.photos/)
3. ~~Core Data~~ SwiftData for image data caching
4. ~~UIKit~~ Migrated to SwiftUI
5. XCTest

## Goals to achieve
1. Follow SOLID principles
2. Fully adopt TDD
3. Use of dependency injection
4. Refactor from MVC to MVVM, safeguard by tests
5. Compose all the components in the composition root
6. Make use of design patterns: adapter, composite and decorator
7. Better naming
8. Learn new frameworks: Async/await, SwiftData and SwiftUI
9. Change UI framework (UIKit to SwiftUI) won't need to change the existing networking, caching parts