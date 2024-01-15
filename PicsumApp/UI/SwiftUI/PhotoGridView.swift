//
//  PhotoGridView.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 13/01/2024.
//

import SwiftUI

struct PhotoGridView: View {
    let delegate: PhotoListViewControllerDelegate
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
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                delegate.loadPhotos()
            }
            .onAppear {
                delegate.loadPhotos()
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
    
    return PhotoGridView(delegate: DummyPhotoListViewControllerDelegate())
}
