//
//  PhotoGridView.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 13/01/2024.
//

import SwiftUI

final class PhotoGridStore: ObservableObject {
    @Published private(set) var isLoading = false
    
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
    }
    
    func loadPhotos() {
        delegate.loadPhotos()
    }
    
    func loadPhotos() async {
        delegate.loadPhotos()
        await finishLoading()
    }
    
    private func finishLoading() async {
        try? await Task.sleep(for: .seconds(0.5))
        if !isLoading {
            await finishLoading()
        }
    }
    
    static var title: String {
        PhotoListViewModel.title
    }
}

struct PhotoGridView: View {
    @ObservedObject var store: PhotoGridStore
    private let range = 0...49
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(range, id: \.self) { index in
                        PhotoGridItem(author: "\(index)", image: nil, isLoading: false)
                            .onAppear {
                                if index == range.upperBound {
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
                await store.loadPhotos()
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
