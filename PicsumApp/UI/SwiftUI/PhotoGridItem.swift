//
//  PhotoGridItem.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 12/01/2024.
//

import SwiftUI

final class PhotoGridItemStore: ObservableObject {
    let delegate: PhotoListCellControllerDelegate
    
    init(delegate: PhotoListCellControllerDelegate) {
        self.delegate = delegate
    }
    
    func loadImage() {
        delegate.loadImage()
    }
}

struct PhotoGridItemContainer: View {
    @ObservedObject var store: PhotoGridItemStore
    let author: String
    
    var body: some View {
        PhotoGridItem(author: author, image: nil, isLoading: false)
            .onAppear(perform: store.loadImage)
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
            
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            
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
