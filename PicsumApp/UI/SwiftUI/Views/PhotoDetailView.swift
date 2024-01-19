//
//  PhotoDetailView.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 14/01/2024.
//

import SwiftUI

@Observable
final class PhotoDetailStore<Image> {
    private(set) var image: Image?
    private(set) var isLoading = false
    
    var photoDetail: PhotoDetail {
        viewModel.photoDetail
    }
    
    private let viewModel: PhotoDetailViewModel<Image>
    let delegate: PhotoDetailViewControllerDelegate
    
    init(viewModel: PhotoDetailViewModel<Image>, delegate: PhotoDetailViewControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.setupBindings()
    }
    
    private func setupBindings() {
        viewModel.didLoad = { [weak self] image in
            self?.image = image
        }
        
        viewModel.onLoad = { [weak self] isLoading in
            self?.isLoading = isLoading
        }
    }
    
    func loadImage() {
        delegate.loadImageData()
    }
}

struct PhotoDetailContainer: View {
    let store: PhotoDetailStore<UIImage>
    
    var body: some View {
        VStack {
            PhotoDetailView(
                detail: store.photoDetail,
                image: store.image,
                isLoading: store.isLoading,
                shouldRetry: false
            )
        }
        .onAppear(perform: store.loadImage)
    }
}

struct PhotoDetailView: View {
    let detail: PhotoDetail
    let image: UIImage?
    let isLoading: Bool
    let shouldRetry: Bool
    
    private var ratio: CGFloat {
        CGFloat(max(detail.width, 1)) / CGFloat(max(detail.height, 1))
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            ZStack {
                Color(.systemGray5)
                
                Image(uiImage: image ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .accessibilityIdentifier("photo-detail-image")
                
                Button(action: {
                    print("button tapped")
                }, label: {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(0.2)
                        .foregroundColor(.white)
                })
                .opacity(shouldRetry ? 1 : 0)
            }
            .aspectRatio(ratio, contentMode: .fit)
            .accessibilityIdentifier("photo-detail-image-stack")
            .shimmering(active: isLoading)
            
            Spacer()
            
            VStack {
                Text(detail.author)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("photo-detail-author")

                Link(detail.webURL.absoluteString, destination: detail.webURL)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("photo-detail-link")
            }
            .padding(8)
        }
    }
}

#Preview {
    PhotoDetailView(
        detail: PhotoDetail(
            author: "Author",
            webURL: URL(string: "http://any-url.com")!,
            width: 16,
            height: 9
        ),
        image: nil,
        isLoading: false,
        shouldRetry: true
    )
}
