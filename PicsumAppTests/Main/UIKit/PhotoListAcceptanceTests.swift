//
//  PhotoListAcceptanceTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 04/01/2024.
//

import XCTest
@testable import PicsumApp

final class PhotoListAcceptanceTests: XCTestCase, AcceptanceTest {
    @MainActor
    func test_onLaunch_displaysPhotosWhenUserHasConnectivity() async throws {
        let photos = try await onLaunch(.online(response))
        
        XCTAssertEqual(photos.numberOfRenderedPhotoView(), 2)
        // Due to iOS 18 update, should avoid dequeuing views without a request from the collection view.
        // Triggering collectionView.dequeueReusableCell for more than once will occur an error.
        // Calling assertImageData will trigger collectionView.dequeueReusableCell once.
        // Therefore, I can't assertImageData for a cell twice in this test.
//        await assertImageData(for: photos, at: 0, asExpected: imageData0())
//        await assertImageData(for: photos, at: 1, asExpected: imageData1())
        
        await photos.loadMore()
        
        XCTAssertEqual(photos.numberOfRenderedPhotoView(), 3)
        await assertImageData(for: photos, at: 0, asExpected: imageData0())
        await assertImageData(for: photos, at: 1, asExpected: imageData1())
        await assertImageData(for: photos, at: 2, asExpected: imageData2())
    }
    
    @MainActor
    func test_onLaunch_doesNotDisplayPhotosWhenUserHasNoConnectivity() async throws {
        let photos = try await onLaunch(.offline)
        
        XCTAssertEqual(photos.numberOfRenderedPhotoView(), 0)
    }
    
    @MainActor
    func test_onLaunch_displaysCachedPhotoImagesWhenCacheExisted() async throws {
        let store = InMemoryImageDataStore.empty
        let photosWithoutCachedImage = try await onLaunch(.online(response), imageDataStore: store)
        
        await assertImageData(for: photosWithoutCachedImage, at: 0, asExpected: imageData0())
        await assertImageData(for: photosWithoutCachedImage, at: 1, asExpected: imageData1())
        
        let photosWithCachedImage = try await onLaunch(.online(responseWithoutImageData), imageDataStore: store)
        
        await assertImageData(for: photosWithCachedImage, at: 0, asExpected: imageData0())
        await assertImageData(for: photosWithCachedImage, at: 1, asExpected: imageData1())
    }
    
    @MainActor
    func test_enteringBackground_invalidatesExpiredImageCache() async throws {
        let store = InMemoryImageDataStore.withExpiredCache
        
        await enterBackground(with: store)
        
        XCTAssertTrue(store.imageCache.isEmpty)
    }
    
    @MainActor
    func test_enteringBackground_doesNotInvalidateNonExpiredImageCache() async throws {
        let store = InMemoryImageDataStore.withNonExpiredCache
        
        await enterBackground(with: store)
        
        XCTAssertFalse(store.imageCache.isEmpty)
    }
    
    @MainActor
    func test_selectPhoto_showsPhotoDetail() async throws {
        let scene = scene(.online(response)) // Have to hold the reference of scene
        let photos = try await onLaunch(scene)
        
        photos.selectPhoto(at: 0)
        
        let photoDetail = try XCTUnwrap(photos.presentedViewController as? PhotoDetailViewController)
        await assertImageData(for: photoDetail, asExpected: imageData0())
    }
    
    // MARK: - Helpers
    
    private func scene(_ client: HTTPClientStub, imageDataStore: InMemoryImageDataStore = .empty) -> SceneDelegate {
        let scene = SceneDelegate(client: client, imageDataStore: imageDataStore)
        scene.window = UIWindow()
        scene.configureWindow()
        return scene
    }
    
    @MainActor
    private func onLaunch(_ scene: SceneDelegate,
                          file: StaticString = #filePath,
                          line: UInt = #line) async throws -> PhotoListViewController {
        let nav = try XCTUnwrap(scene.window?.rootViewController as? UINavigationController, file: file, line: line)
        let vc = try XCTUnwrap(nav.topViewController as? PhotoListViewController, file: file, line: line)
        vc.simulateAppearance()
        await vc.completePhotosLoading()
        return vc
    }
    
    @MainActor
    private func onLaunch(_ client: HTTPClientStub,
                          imageDataStore: InMemoryImageDataStore = .empty,
                          file: StaticString = #filePath,
                          line: UInt = #line) async throws -> PhotoListViewController {
        let scene = scene(client, imageDataStore: imageDataStore)
        return try await onLaunch(scene, file: file, line: line)
    }
    
    @MainActor
    private func enterBackground(with store: InMemoryImageDataStore) async {
        let scene = scene(.online(response), imageDataStore: store)
        scene.sceneWillResignActive(UIApplication.shared.connectedScenes.first!)
        try? await Task.sleep(for: .seconds(0.01)) // Give a little bit time buffer for cache invalidation
    }
    
    private func assertImageData(for photoDetail: PhotoDetailViewController,
                                 asExpected data: Data,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) async {
        await photoDetail.completeImageDataLoading()
        try? await Task.sleep(for: .seconds(0.03)) // Give a little bit time buffer for image data 
        let photoImage = await photoDetail.imageData
        
        XCTAssertEqual(photoImage, data, file: file, line: line)
    }
    
    private func assertImageData(for photoList: PhotoListViewController, 
                                 at item: Int,
                                 asExpected data: Data,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) async {
        let photoImage = await photoList.renderedImage(at: item)
        
        XCTAssertEqual(photoImage, data, file: file, line: line)
    }
}
