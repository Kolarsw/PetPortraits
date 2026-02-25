//
//  PermissionServiceTests.swift
//  PetPortraitsTests
//
//  Created by Kiro
//

import XCTest
import AVFoundation
import Photos
@testable import PetPortraits

@MainActor
class PermissionServiceTests: XCTestCase {
    
    var sut: MockablePermissionService!
    
    override func setUp() {
        super.setUp()
        sut = MockablePermissionService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Camera Permission Status Tests
    
    func testCheckCameraPermission_WhenAuthorized_ReturnsAuthorized() {
        // Given
        sut.mockCameraAuthStatus = .authorized
        
        // When
        let status = sut.checkCameraPermission()
        
        // Then
        XCTAssertEqual(status, .authorized, "Should return authorized when camera permission is granted")
    }
    
    func testCheckCameraPermission_WhenNotDetermined_ReturnsNotDetermined() {
        // Given
        sut.mockCameraAuthStatus = .notDetermined
        
        // When
        let status = sut.checkCameraPermission()
        
        // Then
        XCTAssertEqual(status, .notDetermined, "Should return notDetermined when camera permission not yet requested")
    }
    
    func testCheckCameraPermission_WhenDenied_ReturnsDenied() {
        // Given
        sut.mockCameraAuthStatus = .denied
        
        // When
        let status = sut.checkCameraPermission()
        
        // Then
        XCTAssertEqual(status, .denied, "Should return denied when camera permission is denied")
    }
    
    func testCheckCameraPermission_WhenRestricted_ReturnsDenied() {
        // Given
        sut.mockCameraAuthStatus = .restricted
        
        // When
        let status = sut.checkCameraPermission()
        
        // Then
        XCTAssertEqual(status, .denied, "Should return denied when camera permission is restricted")
    }
    
    // MARK: - Photo Library Permission Status Tests
    
    func testCheckPhotoLibraryPermission_WhenAuthorized_ReturnsAuthorized() {
        // Given
        sut.mockPhotoLibraryAuthStatus = .authorized
        
        // When
        let status = sut.checkPhotoLibraryPermission()
        
        // Then
        XCTAssertEqual(status, .authorized, "Should return authorized when photo library permission is granted")
    }
    
    func testCheckPhotoLibraryPermission_WhenLimited_ReturnsAuthorized() {
        // Given
        sut.mockPhotoLibraryAuthStatus = .limited
        
        // When
        let status = sut.checkPhotoLibraryPermission()
        
        // Then
        XCTAssertEqual(status, .authorized, "Should return authorized when photo library permission is limited (partial access)")
    }
    
    func testCheckPhotoLibraryPermission_WhenNotDetermined_ReturnsNotDetermined() {
        // Given
        sut.mockPhotoLibraryAuthStatus = .notDetermined
        
        // When
        let status = sut.checkPhotoLibraryPermission()
        
        // Then
        XCTAssertEqual(status, .notDetermined, "Should return notDetermined when photo library permission not yet requested")
    }
    
    func testCheckPhotoLibraryPermission_WhenDenied_ReturnsDenied() {
        // Given
        sut.mockPhotoLibraryAuthStatus = .denied
        
        // When
        let status = sut.checkPhotoLibraryPermission()
        
        // Then
        XCTAssertEqual(status, .denied, "Should return denied when photo library permission is denied")
    }
    
    func testCheckPhotoLibraryPermission_WhenRestricted_ReturnsDenied() {
        // Given
        sut.mockPhotoLibraryAuthStatus = .restricted
        
        // When
        let status = sut.checkPhotoLibraryPermission()
        
        // Then
        XCTAssertEqual(status, .denied, "Should return denied when photo library permission is restricted")
    }
    
    // MARK: - Camera Permission Request Tests
    
    func testRequestCameraPermission_WhenGranted_ReturnsTrue() async {
        // Given
        sut.mockCameraRequestResult = true
        
        // When
        let result = await sut.requestCameraPermission()
        
        // Then
        XCTAssertTrue(result, "Should return true when user grants camera permission")
        XCTAssertTrue(sut.didRequestCameraPermission, "Should have called camera permission request")
    }
    
    func testRequestCameraPermission_WhenDenied_ReturnsFalse() async {
        // Given
        sut.mockCameraRequestResult = false
        
        // When
        let result = await sut.requestCameraPermission()
        
        // Then
        XCTAssertFalse(result, "Should return false when user denies camera permission")
        XCTAssertTrue(sut.didRequestCameraPermission, "Should have called camera permission request")
    }
    
    // MARK: - Photo Library Permission Request Tests
    
    func testRequestPhotoLibraryPermission_WhenGranted_ReturnsTrue() async {
        // Given
        sut.mockPhotoLibraryRequestResult = .authorized
        
        // When
        let result = await sut.requestPhotoLibraryPermission()
        
        // Then
        XCTAssertTrue(result, "Should return true when user grants photo library permission")
        XCTAssertTrue(sut.didRequestPhotoLibraryPermission, "Should have called photo library permission request")
    }
    
    func testRequestPhotoLibraryPermission_WhenLimited_ReturnsTrue() async {
        // Given
        sut.mockPhotoLibraryRequestResult = .limited
        
        // When
        let result = await sut.requestPhotoLibraryPermission()
        
        // Then
        XCTAssertTrue(result, "Should return true when user grants limited photo library permission")
        XCTAssertTrue(sut.didRequestPhotoLibraryPermission, "Should have called photo library permission request")
    }
    
    func testRequestPhotoLibraryPermission_WhenDenied_ReturnsFalse() async {
        // Given
        sut.mockPhotoLibraryRequestResult = .denied
        
        // When
        let result = await sut.requestPhotoLibraryPermission()
        
        // Then
        XCTAssertFalse(result, "Should return false when user denies photo library permission")
        XCTAssertTrue(sut.didRequestPhotoLibraryPermission, "Should have called photo library permission request")
    }
    
    func testRequestPhotoLibraryPermission_WhenRestricted_ReturnsFalse() async {
        // Given
        sut.mockPhotoLibraryRequestResult = .restricted
        
        // When
        let result = await sut.requestPhotoLibraryPermission()
        
        // Then
        XCTAssertFalse(result, "Should return false when photo library permission is restricted")
        XCTAssertTrue(sut.didRequestPhotoLibraryPermission, "Should have called photo library permission request")
    }
    
    // MARK: - Edge Case Tests
    
    func testMultipleCameraPermissionChecks_ReturnConsistentResults() {
        // Given
        sut.mockCameraAuthStatus = .authorized
        
        // When
        let firstCheck = sut.checkCameraPermission()
        let secondCheck = sut.checkCameraPermission()
        let thirdCheck = sut.checkCameraPermission()
        
        // Then
        XCTAssertEqual(firstCheck, secondCheck, "Multiple checks should return consistent results")
        XCTAssertEqual(secondCheck, thirdCheck, "Multiple checks should return consistent results")
    }
    
    func testMultiplePhotoLibraryPermissionChecks_ReturnConsistentResults() {
        // Given
        sut.mockPhotoLibraryAuthStatus = .denied
        
        // When
        let firstCheck = sut.checkPhotoLibraryPermission()
        let secondCheck = sut.checkPhotoLibraryPermission()
        let thirdCheck = sut.checkPhotoLibraryPermission()
        
        // Then
        XCTAssertEqual(firstCheck, secondCheck, "Multiple checks should return consistent results")
        XCTAssertEqual(secondCheck, thirdCheck, "Multiple checks should return consistent results")
    }
    
    func testCameraPermissionRequest_DoesNotAffectPhotoLibraryStatus() async {
        // Given
        sut.mockCameraAuthStatus = .notDetermined
        sut.mockPhotoLibraryAuthStatus = .authorized
        sut.mockCameraRequestResult = true
        
        // When
        _ = await sut.requestCameraPermission()
        let photoLibraryStatus = sut.checkPhotoLibraryPermission()
        
        // Then
        XCTAssertEqual(photoLibraryStatus, .authorized, "Camera permission request should not affect photo library status")
    }
    
    func testPhotoLibraryPermissionRequest_DoesNotAffectCameraStatus() async {
        // Given
        sut.mockCameraAuthStatus = .authorized
        sut.mockPhotoLibraryAuthStatus = .notDetermined
        sut.mockPhotoLibraryRequestResult = .authorized
        
        // When
        _ = await sut.requestPhotoLibraryPermission()
        let cameraStatus = sut.checkCameraPermission()
        
        // Then
        XCTAssertEqual(cameraStatus, .authorized, "Photo library permission request should not affect camera status")
    }
}

// MARK: - Mock Permission Service

@MainActor
class MockablePermissionService: PermissionServiceProtocol {
    var mockCameraAuthStatus: AVAuthorizationStatus = .notDetermined
    var mockPhotoLibraryAuthStatus: PHAuthorizationStatus = .notDetermined
    var mockCameraRequestResult: Bool = false
    var mockPhotoLibraryRequestResult: PHAuthorizationStatus = .denied
    
    var didRequestCameraPermission = false
    var didRequestPhotoLibraryPermission = false
    
    func checkCameraPermission() -> PermissionStatus {
        switch mockCameraAuthStatus {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
    
    func requestCameraPermission() async -> Bool {
        didRequestCameraPermission = true
        return mockCameraRequestResult
    }
    
    func checkPhotoLibraryPermission() -> PermissionStatus {
        switch mockPhotoLibraryAuthStatus {
        case .authorized, .limited:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        didRequestPhotoLibraryPermission = true
        return mockPhotoLibraryRequestResult == .authorized || mockPhotoLibraryRequestResult == .limited
    }
}
