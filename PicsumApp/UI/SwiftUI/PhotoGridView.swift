//
//  PhotoGridView.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 13/01/2024.
//

import SwiftUI

final class PhotoGridStore: ObservableObject {
    private(set) var isLoading = false
    @Published private(set) var photos = [Photo]()
    
    private let viewModel: PhotoListViewModel
    let delegate: PhotoListViewControllerDelegate
    
    init(viewModel: PhotoListViewModel, delegate: PhotoListViewControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.setupBindings()
    }
    
    private func setupBindings() {
        viewModel.onLoad = { [weak self] isLoading in
            self?.isLoading = isLoading
        }
        
        viewModel.didLoad = { [weak self] photos in
            self?.photos = photos
        }
    }
    
    func loadPhotos() {
        isLoading = true
        delegate.loadPhotos()
    }
    
    func asyncLoadPhotos() async {
        loadPhotos()
        await trackFinishLoading()
    }
    
    private func trackFinishLoading() async {
        let finishedLoading = !isLoading
        guard finishedLoading else { return }
        
        try? await Task.sleep(for: .seconds(0.1))
        await trackFinishLoading()
    }
    
    static var title: String {
        PhotoListViewModel.title
    }
}

struct PhotoGridView: View {
    @ObservedObject var store: PhotoGridStore
    let gridItem: (Photo) -> AnyView
    let onGridItemDisappear: (Photo) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(zip(store.photos.indices, store.photos)), id: \.1.id) { index, photo in
                        gridItem(photo)
                            .onAppear {
                                let isTheLastOne = index == store.photos.count-1
                                if isTheLastOne {
                                    print("last item appeared")
                                }
                            }
                            .onDisappear { onGridItemDisappear(photo) }
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
    }
}

#Preview {
    class DummyPhotoListViewControllerDelegate: PhotoListViewControllerDelegate {
        var loadPhotosTask: Task<Void, Never>?
        var loadMorePhotosTask: Task<Void, Never>?
        
        func loadPhotos() {}
        func loadMorePhotos() {}
    }
    
    let viewModel = PhotoGridStore(viewModel: PhotoListViewModel(), delegate: DummyPhotoListViewControllerDelegate())
    
    return PhotoGridView(
        store: viewModel,
        gridItem: { photo in
            PhotoGridItem(author: photo.author, image: nil, isLoading: false).eraseToAnyView()
        }, 
        onGridItemDisappear: { _ in }
    )
}
