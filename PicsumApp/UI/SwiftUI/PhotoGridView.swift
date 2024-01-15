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
    
    private let model: PhotoListViewModel
    let delegate: PhotoListViewControllerDelegate
    
    init(model: PhotoListViewModel, delegate: PhotoListViewControllerDelegate) {
        self.model = model
        self.delegate = delegate
        self.setupBindings()
    }
    
    private func setupBindings() {
        model.onLoad = { [weak self] isLoading in
            self?.isLoading = isLoading
        }
        
        model.didLoad = { [weak self] photos in
            self?.photos = photos
        }
    }
    
    func loadPhotos() {
        isLoading = true
        delegate.loadPhotos()
    }
    
    func trackFinishLoading() async {
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(zip(store.photos.indices, store.photos)), id: \.1.id) { index, photo in
                        PhotoGridItem(author: photo.author, image: nil, isLoading: false)
                            .onAppear {
                                if index == store.photos.count-1 {
                                    print("last item appeared")
                                }
                            }
                    }
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle(PhotoGridStore.title)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                store.loadPhotos()
                await store.trackFinishLoading()
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
    
    let viewModel = PhotoGridStore(model: PhotoListViewModel(), delegate: DummyPhotoListViewControllerDelegate())
    
    return PhotoGridView(store: viewModel)
}
