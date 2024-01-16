//
//  PhotoGridItem.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 12/01/2024.
//

import SwiftUI

final class PhotoGridItemStore<Image>: ObservableObject {
    @Published private(set) var image: Image?
    @Published private(set) var isLoading = false
    
    private let viewModel: PhotoImageViewModel<Image>
    let delegate: PhotoListCellControllerDelegate
    
    init(viewModel: PhotoImageViewModel<Image>, delegate: PhotoListCellControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.setupBindings()
    }
    
    private func setupBindings() {
        viewModel.didLoadImage = { [weak self] image in
            self?.image = image
        }
        
        viewModel.onLoadImage = { [weak self] isLoading in
            self?.isLoading = isLoading
        }
    }
    
    func loadImage() {
        delegate.loadImage()
    }
    
    func cancelLoadImage() {
        delegate.cancelLoad()
    }
}

struct PhotoGridItemContainer: View {
    @ObservedObject var store: PhotoGridItemStore<UIImage>
    let author: String
    
    var body: some View {
        VStack {
            PhotoGridItem(author: author, image: store.image, isLoading: store.isLoading)
        }
        .accessibilityIdentifier("photo-grid-item-container-stack")
        .onAppear(perform: store.loadImage)
        .onDisappear(perform: store.cancelLoadImage)
    }
}

struct PhotoGridItem: View {
    let author: String
    let image: UIImage?
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            Color(.systemGray5)
                .shimmering(active: isLoading)
            
            Image(systemName: "photo")
                .resizable()
                .foregroundStyle(.secondary)
                .scaledToFit()
                .scaleEffect(0.35)
            
            Image(uiImage: image ?? UIImage())
                .resizable()
                .scaledToFill()
                .accessibilityIdentifier("photo-grid-item-image")
            
            VStack {
                Spacer()
                Text(author)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.thinMaterial)
                    .accessibilityIdentifier("photo-grid-item-author")
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.tertiary, lineWidth: 1)
        )
    }
}

#Preview {
    PhotoGridItem(author: "Author", image: nil, isLoading: true)
        .frame(width: 200, alignment: .center)
        
}
