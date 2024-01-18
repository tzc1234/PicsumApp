//
//  PhotoGridView.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 13/01/2024.
//

import SwiftUI

@Observable
final class PhotoGridStore {
    private(set) var isLoading = false
    private(set) var photos = [Photo]()
    private(set) var errorMessage: String?
    
    private var _showError = false
    var showError: Binding<Bool> {
        Binding(
            get: { self._showError },
            set: { showError in
                if !showError {
                    self.errorMessage = nil
                }
                self._showError = showError
            }
        )
    }
    
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
        
        viewModel.didLoadMore = { [weak self] photos in
            self?.photos += photos
        }
        
        viewModel.onError = { [weak self] errorMessage in
            self?.errorMessage = errorMessage
            self?._showError = errorMessage != nil
        }
    }
    
    func hideError() {
        showError.wrappedValue = false
    }
    
    @MainActor
    func loadPhotos() {
        isLoading = true
        cancelAllPendingPhotosTask()
        delegate.loadPhotos()
    }
    
    private func cancelAllPendingPhotosTask() {
        delegate.loadPhotosTask?.cancel()
        delegate.loadMorePhotosTask?.cancel()
    }
    
    func asyncLoadPhotos() async {
        await loadPhotos()
        await trackFinishLoading()
    }
    
    private func trackFinishLoading() async {
        guard isLoading else { return }
        
        try? await Task.sleep(for: .seconds(0.1))
        await trackFinishLoading()
    }
    
    @MainActor
    func loadMorePhotos() {
        delegate.loadMorePhotos()
    }
    
    static var title: String {
        PhotoListViewModel.title
    }
    
    static var errorTitle: String {
        PhotoListViewModel.errorTitle
    }
}

struct PhotoGridView: View {
    let store: PhotoGridStore
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
                                    store.loadMorePhotos()
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
        .accessibilityIdentifier("photo-grid-outmost-view")
        .alert(PhotoGridStore.errorTitle, isPresented: store.showError) {
            Button("OK", role: .cancel, action: { store.hideError() })
        } message: {
            Text(store.errorMessage ?? "")
        }
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
//            viewModel.didFinishLoading(with: [
//                Photo(
//                    id: "0",
//                    author: "Author 0",
//                    width: 1,
//                    height: 1,
//                    webURL: URL(string: "https://any-url.com")!,
//                    url: URL(string: "https://0.com")!
//                ),
//                Photo(
//                    id: "1",
//                    author: "Author 1",
//                    width: 1,
//                    height: 1,
//                    webURL: URL(string: "https://any-url.com")!,
//                    url: URL(string: "https://1.com")!
//                ),
//                Photo(
//                    id: "2",
//                    author: "Author 2",
//                    width: 1,
//                    height: 1,
//                    webURL: URL(string: "https://any-url.com")!,
//                    url: URL(string: "https://2.com")!
//                )
//            ])
            viewModel.didFinishLoadingWithError()
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
        onGridItemDisappear: { _ in }
    )
}
