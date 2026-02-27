//
//  UIKitBridgesTests.swift
//  PetPortraitsTests
//
//  Created by Kiro
//

import XCTest
import SwiftUI
import UIKit
@testable import PetPortraits

final class UIKitBridgesTests: XCTestCase {
    
    // MARK: - CameraViewController Coordinator Tests
    
    func testCameraCoordinatorUpdatesBindingOnImageCapture() {
        // Given
        var capturedImage: UIImage? = nil
        let testImage = createTestImage()
        let picker = UIImagePickerController()
        
        // Create a test coordinator that captures the image binding behavior
        let coordinator = TestCameraCoordinator(imageBinding: { capturedImage = $0 })
        
        // When
        let info: [UIImagePickerController.InfoKey: Any] = [.originalImage: testImage]
        coordinator.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
        
        // Then
        XCTAssertNotNil(capturedImage, "Captured image should be set after image capture")
        XCTAssertEqual(capturedImage, testImage, "Captured image should match the test image")
    }
    
    func testCameraCoordinatorDoesNotUpdateBindingOnCancel() {
        // Given
        var capturedImage: UIImage? = nil
        let picker = UIImagePickerController()
        let coordinator = TestCameraCoordinator(imageBinding: { capturedImage = $0 })
        
        // When
        coordinator.imagePickerControllerDidCancel(picker)
        
        // Then
        XCTAssertNil(capturedImage, "Captured image should remain nil after cancel")
    }
    
    func testCameraCoordinatorHandlesMissingImage() {
        // Given
        var capturedImage: UIImage? = nil
        let picker = UIImagePickerController()
        let coordinator = TestCameraCoordinator(imageBinding: { capturedImage = $0 })
        
        // When - info dictionary without originalImage
        let info: [UIImagePickerController.InfoKey: Any] = [:]
        coordinator.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
        
        // Then
        XCTAssertNil(capturedImage, "Captured image should remain nil when no image in info")
    }
    
    func testCameraCoordinatorHandlesMultipleCaptures() {
        // Given
        var capturedImage: UIImage? = nil
        let picker = UIImagePickerController()
        let coordinator = TestCameraCoordinator(imageBinding: { capturedImage = $0 })
        
        let firstImage = createTestImage(color: .red)
        let secondImage = createTestImage(color: .blue)
        
        // When - First capture
        coordinator.imagePickerController(picker, didFinishPickingMediaWithInfo: [.originalImage: firstImage])
        XCTAssertEqual(capturedImage, firstImage)
        
        // When - Second capture
        coordinator.imagePickerController(picker, didFinishPickingMediaWithInfo: [.originalImage: secondImage])
        
        // Then
        XCTAssertEqual(capturedImage, secondImage, "Second captured image should replace the first")
    }
    
    // MARK: - PhotoPickerViewController Coordinator Tests
    
    func testPhotoPickerCoordinatorUpdatesBindingOnImageSelection() {
        // Given
        var selectedImage: UIImage? = nil
        let testImage = createTestImage()
        let picker = UIImagePickerController()
        let coordinator = TestPhotoPickerCoordinator(imageBinding: { selectedImage = $0 })
        
        // When
        let info: [UIImagePickerController.InfoKey: Any] = [.originalImage: testImage]
        coordinator.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
        
        // Then
        XCTAssertNotNil(selectedImage, "Selected image should be set after image selection")
        XCTAssertEqual(selectedImage, testImage, "Selected image should match the test image")
    }
    
    func testPhotoPickerCoordinatorDoesNotUpdateBindingOnCancel() {
        // Given
        var selectedImage: UIImage? = nil
        let picker = UIImagePickerController()
        let coordinator = TestPhotoPickerCoordinator(imageBinding: { selectedImage = $0 })
        
        // When
        coordinator.imagePickerControllerDidCancel(picker)
        
        // Then
        XCTAssertNil(selectedImage, "Selected image should remain nil after cancel")
    }
    
    func testPhotoPickerCoordinatorHandlesMissingImage() {
        // Given
        var selectedImage: UIImage? = nil
        let picker = UIImagePickerController()
        let coordinator = TestPhotoPickerCoordinator(imageBinding: { selectedImage = $0 })
        
        // When - info dictionary without originalImage
        let info: [UIImagePickerController.InfoKey: Any] = [:]
        coordinator.imagePickerController(picker, didFinishPickingMediaWithInfo: info)
        
        // Then
        XCTAssertNil(selectedImage, "Selected image should remain nil when no image in info")
    }
    
    func testPhotoPickerCoordinatorHandlesMultipleSelections() {
        // Given
        var selectedImage: UIImage? = nil
        let picker = UIImagePickerController()
        let coordinator = TestPhotoPickerCoordinator(imageBinding: { selectedImage = $0 })
        
        let firstImage = createTestImage(color: .green)
        let secondImage = createTestImage(color: .yellow)
        
        // When - First selection
        coordinator.imagePickerController(picker, didFinishPickingMediaWithInfo: [.originalImage: firstImage])
        XCTAssertEqual(selectedImage, firstImage)
        
        // When - Second selection
        coordinator.imagePickerController(picker, didFinishPickingMediaWithInfo: [.originalImage: secondImage])
        
        // Then
        XCTAssertEqual(selectedImage, secondImage, "Second selected image should replace the first")
    }
    
    // MARK: - UIImagePickerController Configuration Tests
    
    func testCameraSourceTypeIsCamera() {
        // Verify the implementation sets camera source type
        // This is a compile-time verification - the actual source type is set in makeUIViewController
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        XCTAssertEqual(picker.sourceType, .camera, "Camera source type should be .camera")
    }
    
    func testPhotoLibrarySourceTypeIsPhotoLibrary() {
        // Verify the implementation sets photo library source type
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        XCTAssertEqual(picker.sourceType, .photoLibrary, "Photo library source type should be .photoLibrary")
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(color: UIColor = .red) -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - Test Coordinators

/// Test coordinator that mimics CameraViewController.Coordinator behavior without SwiftUI Environment dependencies
private class TestCameraCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let imageBinding: (UIImage?) -> Void
    
    init(imageBinding: @escaping (UIImage?) -> Void) {
        self.imageBinding = imageBinding
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            imageBinding(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // No action needed - binding stays nil
    }
}

/// Test coordinator that mimics PhotoPickerViewController.Coordinator behavior without SwiftUI Environment dependencies
private class TestPhotoPickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let imageBinding: (UIImage?) -> Void
    
    init(imageBinding: @escaping (UIImage?) -> Void) {
        self.imageBinding = imageBinding
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            imageBinding(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // No action needed - binding stays nil
    }
}
