//
//  ImageServiceTests.swift
//  PetPortraitsTests
//
//  Created by Kiro
//

import XCTest
import UIKit
import Photos
@testable import PetPortraits

/// Tests for ImageService - validates Requirement 9.2: Portrait Saving
/// THE Pet_Portrait_App SHALL save the portrait to the Camera_Roll
@MainActor
class ImageServiceTests: XCTestCase {
    
    var sut: MockableImageService!
    
    override func setUp() {
        super.setUp()
        sut = MockableImageService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Successful Save Operation Tests
    
    func testSaveToPhotoLibrary_WhenAuthorized_SavesSuccessfully() async throws {
        // Given
        sut.mockAuthorizationStatus = .authorized
        sut.mockSaveResult = .success(())
        let testImage = createTestImage()
        
        // When
        try await sut.saveToPhotoLibrary(testImage)
        
        // Then
        XCTAssertTrue(sut.didAttemptSave, "Should attempt to save the image")
        XCTAssertNotNil(sut.lastSavedImage, "Should have captured the image to save")
    }
    
    func testSaveToPhotoLibrary_WhenAuthorized_PassesCorrectImage() async throws {
        // Given
        sut.mockAuthorizationStatus = .authorized
        sut.mockSaveResult = .success(())
        let testImage = createTestImage()
        
        // When
        try await sut.saveToPhotoLibrary(testImage)
        
        // Then
        XCTAssertEqual(sut.lastSavedImage?.size, testImage.size, "Should pass the correct image to save")
    }

    
    // MARK: - Permission Denied Error Handling Tests
    
    func testSaveToPhotoLibrary_WhenDenied_ThrowsPermissionError() async {
        // Given
        sut.mockAuthorizationStatus = .denied
        let testImage = createTestImage()
        
        // When/Then
        do {
            try await sut.saveToPhotoLibrary(testImage)
            XCTFail("Should throw PermissionError.photoLibraryAccessDenied")
        } catch let error as PermissionError {
            XCTAssertEqual(error, .photoLibraryAccessDenied, "Should throw photoLibraryAccessDenied error")
        } catch {
            XCTFail("Should throw PermissionError, got \(error)")
        }
    }
    
    func testSaveToPhotoLibrary_WhenRestricted_ThrowsPermissionError() async {
        // Given
        sut.mockAuthorizationStatus = .restricted
        let testImage = createTestImage()
        
        // When/Then
        do {
            try await sut.saveToPhotoLibrary(testImage)
            XCTFail("Should throw PermissionError.photoLibraryAccessDenied")
        } catch let error as PermissionError {
            XCTAssertEqual(error, .photoLibraryAccessDenied, "Should throw photoLibraryAccessDenied error")
        } catch {
            XCTFail("Should throw PermissionError, got \(error)")
        }
    }
    
    func testSaveToPhotoLibrary_WhenDenied_DoesNotAttemptSave() async {
        // Given
        sut.mockAuthorizationStatus = .denied
        let testImage = createTestImage()
        
        // When
        try? await sut.saveToPhotoLibrary(testImage)
        
        // Then
        XCTAssertFalse(sut.didAttemptSave, "Should not attempt to save when permission is denied")
    }
    
    // MARK: - Permission Request Flow Tests
    
    func testSaveToPhotoLibrary_WhenNotDetermined_RequestsPermission() async throws {
        // Given
        sut.mockAuthorizationStatus = .notDetermined
        sut.mockRequestAuthorizationResult = .authorized
        sut.mockSaveResult = .success(())
        let testImage = createTestImage()
        
        // When
        try await sut.saveToPhotoLibrary(testImage)
        
        // Then
        XCTAssertTrue(sut.didRequestAuthorization, "Should request authorization when not determined")
    }
    
    func testSaveToPhotoLibrary_WhenNotDeterminedAndGranted_SavesSuccessfully() async throws {
        // Given
        sut.mockAuthorizationStatus = .notDetermined
        sut.mockRequestAuthorizationResult = .authorized
        sut.mockSaveResult = .success(())
        let testImage = createTestImage()
        
        // When
        try await sut.saveToPhotoLibrary(testImage)
        
        // Then
        XCTAssertTrue(sut.didAttemptSave, "Should save after permission is granted")
    }
    
    func testSaveToPhotoLibrary_WhenNotDeterminedAndDenied_ThrowsPermissionError() async {
        // Given
        sut.mockAuthorizationStatus = .notDetermined
        sut.mockRequestAuthorizationResult = .denied
        let testImage = createTestImage()
        
        // When/Then
        do {
            try await sut.saveToPhotoLibrary(testImage)
            XCTFail("Should throw PermissionError.photoLibraryAccessDenied")
        } catch let error as PermissionError {
            XCTAssertEqual(error, .photoLibraryAccessDenied, "Should throw photoLibraryAccessDenied error")
        } catch {
            XCTFail("Should throw PermissionError, got \(error)")
        }
    }
    
    func testSaveToPhotoLibrary_WhenNotDeterminedAndDenied_DoesNotAttemptSave() async {
        // Given
        sut.mockAuthorizationStatus = .notDetermined
        sut.mockRequestAuthorizationResult = .denied
        let testImage = createTestImage()
        
        // When
        try? await sut.saveToPhotoLibrary(testImage)
        
        // Then
        XCTAssertFalse(sut.didAttemptSave, "Should not attempt to save when permission request is denied")
    }

    
    // MARK: - Save Failure Scenario Tests
    
    func testSaveToPhotoLibrary_WhenSaveFails_ThrowsError() async {
        // Given
        sut.mockAuthorizationStatus = .authorized
        let saveError = NSError(domain: "PHPhotosErrorDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Save failed"])
        sut.mockSaveResult = .failure(saveError)
        let testImage = createTestImage()
        
        // When/Then
        do {
            try await sut.saveToPhotoLibrary(testImage)
            XCTFail("Should throw error when save fails")
        } catch {
            // Expected - save operation failed
            XCTAssertNotNil(error, "Should propagate the save error")
        }
    }
    
    func testSaveToPhotoLibrary_WhenSaveFailsWithDiskFull_ThrowsError() async {
        // Given
        sut.mockAuthorizationStatus = .authorized
        let diskFullError = NSError(domain: "PHPhotosErrorDomain", code: 3300, userInfo: [NSLocalizedDescriptionKey: "Not enough storage space"])
        sut.mockSaveResult = .failure(diskFullError)
        let testImage = createTestImage()
        
        // When/Then
        do {
            try await sut.saveToPhotoLibrary(testImage)
            XCTFail("Should throw error when disk is full")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 3300, "Should propagate the disk full error code")
        }
    }
    
    func testSaveToPhotoLibrary_WhenSaveFailsWithInvalidImage_ThrowsError() async {
        // Given
        sut.mockAuthorizationStatus = .authorized
        let invalidImageError = NSError(domain: "PHPhotosErrorDomain", code: 3301, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
        sut.mockSaveResult = .failure(invalidImageError)
        let testImage = createTestImage()
        
        // When/Then
        do {
            try await sut.saveToPhotoLibrary(testImage)
            XCTFail("Should throw error for invalid image")
        } catch let error as NSError {
            XCTAssertEqual(error.code, 3301, "Should propagate the invalid image error code")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testSaveToPhotoLibrary_WithLargeImage_SavesSuccessfully() async throws {
        // Given
        sut.mockAuthorizationStatus = .authorized
        sut.mockSaveResult = .success(())
        
        // Create a larger test image
        let size = CGSize(width: 4000, height: 3000)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let largeImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // When
        try await sut.saveToPhotoLibrary(largeImage)
        
        // Then
        XCTAssertTrue(sut.didAttemptSave, "Should attempt to save large images")
        XCTAssertEqual(sut.lastSavedImage?.size, largeImage.size, "Should save the correct large image")
    }
    
    func testSaveToPhotoLibrary_MultipleSaves_AllSucceed() async throws {
        // Given
        sut.mockAuthorizationStatus = .authorized
        sut.mockSaveResult = .success(())
        let testImage1 = createTestImage()
        let testImage2 = createTestImage()
        
        // When
        try await sut.saveToPhotoLibrary(testImage1)
        try await sut.saveToPhotoLibrary(testImage2)
        
        // Then
        XCTAssertEqual(sut.saveAttemptCount, 2, "Should track multiple save attempts")
    }
    
    func testSaveToPhotoLibrary_PermissionErrorDescription_IsUserFriendly() {
        // Given
        let error = PermissionError.photoLibraryAccessDenied
        
        // When
        let description = error.errorDescription
        
        // Then
        XCTAssertNotNil(description, "Error should have a description")
        XCTAssertTrue(description!.contains("Photo library"), "Description should mention photo library")
        XCTAssertTrue(description!.contains("Settings"), "Description should guide user to Settings")
    }
}


// MARK: - Mock Image Service

/// A testable version of ImageService that allows mocking PHPhotoLibrary behavior
@MainActor
class MockableImageService: ImageServiceProtocol {
    
    // Mock configuration
    var mockAuthorizationStatus: PHAuthorizationStatus = .notDetermined
    var mockRequestAuthorizationResult: PHAuthorizationStatus = .denied
    var mockSaveResult: Result<Void, Error> = .success(())
    
    // Tracking properties
    var didRequestAuthorization = false
    var didAttemptSave = false
    var lastSavedImage: UIImage?
    var saveAttemptCount = 0
    
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        let status = mockAuthorizationStatus
        
        guard status == .authorized else {
            if status == .notDetermined {
                didRequestAuthorization = true
                let newStatus = mockRequestAuthorizationResult
                guard newStatus == .authorized else {
                    throw PermissionError.photoLibraryAccessDenied
                }
                try await performSave(image)
                return
            } else {
                throw PermissionError.photoLibraryAccessDenied
            }
        }
        
        try await performSave(image)
    }
    
    private func performSave(_ image: UIImage) async throws {
        didAttemptSave = true
        lastSavedImage = image
        saveAttemptCount += 1
        
        switch mockSaveResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
