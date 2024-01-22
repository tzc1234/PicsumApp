//
//  PhotoDetailView.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 14/01/2024.
//

import SwiftUI

struct PhotoDetailContainer: View {
    let store: PhotoDetailStore<UIImage>
    
    var body: some View {
        VStack {
            PhotoDetailView(
                detail: store.photoDetail,
                image: store.image,
                isLoading: store.isLoading,
                shouldRetry: store.shouldReload, 
                reloadButtonTapped: store.loadImage
            )
        }
    }
}

struct PhotoDetailView: View {
    let detail: PhotoDetail
    let image: UIImage?
    let isLoading: Bool
    let shouldRetry: Bool
    let reloadButtonTapped: () -> Void
    
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
                
                Button(action: reloadButtonTapped, label: {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(0.2)
                        .foregroundColor(.white)
                })
                .accessibilityIdentifier("photo-detail-reload-button")
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
        shouldRetry: true,
        reloadButtonTapped: {}
    )
}
