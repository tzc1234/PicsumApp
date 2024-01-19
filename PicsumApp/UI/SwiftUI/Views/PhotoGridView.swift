//
//  PhotoGridView.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 13/01/2024.
//

import SwiftUI

struct PhotoGridView: View {
    let store: PhotoGridStore
    let gridItem: (Photo) -> AnyView
    let onGridItemDisappear: (Photo) -> Void
    let nextView: (Photo) -> AnyView
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(zip(store.photos.indices, store.photos)), id: \.1.id) { index, photo in
                        ZStack {
                            gridItem(photo)
                                .onAppear {
                                    let isTheLastOne = index == store.photos.count-1
                                    if isTheLastOne {
                                        store.loadMorePhotos()
                                    }
                                }
                                .onDisappear {
                                    onGridItemDisappear(photo)
                                }
                            
                            Button {
                                store.photoForPresentingSheet.wrappedValue = photo
                            } label: {
                                Color.clear
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle(PhotoGridStore.title)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await store.asyncLoadPhotos()
            }
            .onAppear {
                store.loadPhotos()
            }
        }
        .accessibilityIdentifier("photo-grid-outmost-view")
        .alert(PhotoGridStore.errorTitle, isPresented: store.showError) {
            Button("OK", role: .cancel, action: { store.hideError() })
        } message: {
            Text(store.errorMessage ?? "")
        }
        // Since @State can't be accessed outside this view, purple warning occurred:
        // "Accessing State's value outside of being installed on a View.
        //  This will result in a constant Binding of the initial value and will not update."
        // I have to move `photoForPresentingSheet` from this view to `PhotoGridStore`. 
        // Also, need to use inspectableSheet to expose params to test. This is the limitation of the framework.
        .inspectableSheet(item: store.photoForPresentingSheet) { photo in
            nextView(photo)
        }
    }
}

extension PhotoGridStore {
    var photoForPresentingSheet: Binding<Photo?> {
        Binding(
            get: { self.selectedPhoto },
            set: { self.selectedPhoto = $0 }
        )
    }
    
    var showError: Binding<Bool> {
        Binding(
            get: { self.errorMessage != nil },
            set: { showError in
                if !showError {
                    self.clearErrorMessage()
                }
            }
        )
    }
    
    func hideError() {
        clearErrorMessage()
    }
}

#Preview {
    class PhotoListViewControllerDelegateStub: PhotoListViewControllerDelegate {
        var loadPhotosTask: Task<Void, Never>?
        var loadMorePhotosTask: Task<Void, Never>?
        let viewModel: PhotoListViewModel
        
        init(viewModel: PhotoListViewModel) {
            self.viewModel = viewModel
        }
        
        func loadPhotos() {
            viewModel.didFinishLoading(with: [
                Photo(
                    id: "0",
                    author: "Author 0",
                    width: 1,
                    height: 1,
                    webURL: URL(string: "https://any-url.com")!,
                    url: URL(string: "https://0.com")!
                ),
                Photo(
                    id: "1",
                    author: "Author 1",
                    width: 1,
                    height: 1,
                    webURL: URL(string: "https://any-url.com")!,
                    url: URL(string: "https://1.com")!
                ),
                Photo(
                    id: "2",
                    author: "Author 2",
                    width: 1,
                    height: 1,
                    webURL: URL(string: "https://any-url.com")!,
                    url: URL(string: "https://2.com")!
                )
            ])
        }
        
        func loadMorePhotos() {}
    }
    
    func getImage(url: URL) -> UIImage {
        switch url.absoluteString {
        case "https://0.com":
            return .make(withColor: .red)
        case "https://1.com":
            return .make(withColor: .green)
        case "https://2.com":
            return .make(withColor: .blue)
        default:
            return .make(withColor: .gray)
        }
    }
    
    let delegate = PhotoListViewControllerDelegateStub(viewModel: PhotoListViewModel())
    let store = PhotoGridStore(viewModel: delegate.viewModel, delegate: delegate)
    
    return PhotoGridView(
        store: store,
        gridItem: { photo in
            PhotoGridItem(
                author: photo.author,
                image: getImage(url: photo.url),
                isLoading: false
            )
            .eraseToAnyView()
        },
        onGridItemDisappear: { _ in }, 
        nextView: { _ in EmptyView().eraseToAnyView() }
    )
}
