//
//  PhotoDetailView.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 14/01/2024.
//

import SwiftUI

@Observable
final class PhotoDetailStore<Image> {
    var photoDetail: PhotoDetail {
        viewModel.photoDetail
    }
    
    private let viewModel: PhotoDetailViewModel<Image>
    let delegate: PhotoDetailViewControllerDelegate
    
    init(viewModel: PhotoDetailViewModel<Image>, delegate: PhotoDetailViewControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    func loadImage() {
        delegate.loadImageData()
    }
}

struct PhotoDetailContainer: View {
    let store: PhotoDetailStore<UIImage>
    
    var body: some View {
        VStack {
            PhotoDetailView(detail: store.photoDetail, image: nil, isLoading: false, shouldRetry: false)
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
                
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
                
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
