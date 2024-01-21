//
//  PhotoGridView.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 13/01/2024.
//

import SwiftUI

struct PhotoGridView<ItemView: View, NextView: View>: View {
    let store: PhotoGridStore
    let gridItem: (Photo) -> ItemView
    let onGridItemDisappear: (Photo) -> Void
    let nextView: (Photo) -> NextView
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(store.photos) { photo in
                        ZStack {
                            gridItem(photo)
                                .onAppear {
                                    let isTheLastOne = photo == store.photos.last
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
        }
        .accessibilityIdentifier("photo-grid-outmost-view")
        .alert(PhotoGridStore.errorTitle, isPresented: store.isErrorShown) {
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
    
    var isErrorShown: Binding<Bool> {
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

#Preview("Success case") {
    let delegate = PhotoListViewControllerDelegateStub(stub: .success(previewPhotos))
    let store = PhotoGridStore(viewModel: delegate.viewModel, delegate: delegate)
    return PhotoGridView(
        store: store,
        gridItem: { photo in
            PhotoGridItem(
                author: photo.author,
                image: getPreviewUIImage(by: photo.url),
                isLoading: false
            )
        },
        onGridItemDisappear: { _ in }, 
        nextView: { _ in EmptyView() }
    )
}

#Preview("Failure case") {
    let delegate = PhotoListViewControllerDelegateStub(stub: .failure(NSError(domain: "error", code: 0)))
    let store = PhotoGridStore(viewModel: delegate.viewModel, delegate: delegate)
    return PhotoGridView(
        store: store,
        gridItem: { photo in
            PhotoGridItem(
                author: photo.author,
                image: nil,
                isLoading: false
            )
        },
        onGridItemDisappear: { _ in },
        nextView: { _ in EmptyView() }
    )
}
