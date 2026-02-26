//
//  PortraitViewModelTests.swift
//  PetPortraitsTests
//
//  Created by Kiro
//

import XCTest
import UIKit
@testable import PetPortraits

/// Tests for PortraitViewModel - validates Requirements 6.1, 6.2, 7.1, 7.2, 8.1, 8.2, 9.2, 10.1, 13.2, 13.4, 13.5
/// WHEN the user inputs a Style_Prompt and taps "Generate", THE Pet_Portrait_App SHALL send the selected image and Style_Prompt to the Nano_Banana_Pro_API
/// WHEN the Nano_Banana_Pro_API returns a generated portrait, THE Pet_Portrait_App SHALL display the portrait on the Results_Screen
/// WHILE the Pet_Portrait_App is waiting for a response from the Nano_Banana_Pro_API, THE Pet_Portrait_App SHALL disable the "Generate" button
/// WHILE the Pet_Portrait_App is waiting for a response from the Nano_Banana_Pro_API, THE Pet_Portrait_App SHALL display the Loading_Animation
/// WHEN the user taps "Refresh" on the Results_Screen, THE Pet_Portrait_App SHALL send the same image and Style_Prompt to the Nano_Banana_Pro_API
/// WHEN the Nano_Banana_Pro_API returns the new variation, THE Pet_Portrait_App SHALL replace the displayed portrait with the new result
/// WHEN the user taps "Save" on the Results_Screen, THE Pet_Portrait_App SHALL save the portrait to the Camera_Roll
/// WHEN the user taps "Share" on the Results_Screen, THE Pet_Portrait_App SHALL open the Share_Sheet populated with the generated portrait image
/// IF the Nano_Banana_Pro_API returns an error response, THEN THE Pet_Portrait_App SHALL preserve the selected photo and Style_Prompt
/// IF a network failure occurs during API communication, THEN THE Pet_Portrait_App SHALL preserve the selected photo and Style_Prompt
/// IF an error occurs, THEN THE Pet_Portrait_App SHALL enable the user to retry the generation request
@MainActor
class PortraitViewModelTests: XCTestCase {
    
    var sut: PortraitViewModel!
    var mockAPIService: MockAPIService!
    var mockImageService: MockImageService!
    var mockPermissionService: MockPermissionService!
    
    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIService()
        mockImageService = MockImageService()
        mockPermissionService = MockPermissionService()
        sut = PortraitViewModel(
            apiService: mockAPIService,
            imageService: mockImageService,
            permissionService: mockPermissionService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockAPIService = nil
        mockImageService = nil
        mockPermissionService = nil
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
    
    private func createGeneratedImage() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        UIGraphicsBeginImageContext(size)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    
    // MARK: - Initial State Tests
    
    func testInitialState_SelectedImageIsNil() {
        // Then
        XCTAssertNil(sut.selectedImage, "Initial selectedImage should be nil")
    }
    
    func testInitialState_StylePromptIsEmpty() {
        // Then
        XCTAssertEqual(sut.stylePrompt, "", "Initial stylePrompt should be empty")
    }
    
    func testInitialState_GeneratedPortraitIsNil() {
        // Then
        XCTAssertNil(sut.generatedPortrait, "Initial generatedPortrait should be nil")
    }
    
    func testInitialState_IsLoadingIsFalse() {
        // Then
        XCTAssertFalse(sut.isLoading, "Initial isLoading should be false")
    }
    
    func testInitialState_ErrorMessageIsNil() {
        // Then
        XCTAssertNil(sut.errorMessage, "Initial errorMessage should be nil")
    }
    
    // MARK: - Generate Portrait Success Tests (Requirements 6.1, 6.2)
    
    func testGeneratePortrait_WhenSuccessful_UpdatesGeneratedPortrait() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "watercolor style"
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertNotNil(sut.generatedPortrait, "Should update generatedPortrait on success")
    }
    
    func testGeneratePortrait_WhenSuccessful_CallsAPIServiceWithCorrectImage() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "oil painting"
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertNotNil(mockAPIService.capturedImage, "Should call API service with image")
    }
    
    func testGeneratePortrait_WhenSuccessful_CallsAPIServiceWithCorrectPrompt() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        let stylePrompt = "cartoon style"
        sut.selectedImage = testImage
        sut.stylePrompt = stylePrompt
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertEqual(mockAPIService.capturedStylePrompt, stylePrompt, "Should call API service with correct style prompt")
    }
    
    func testGeneratePortrait_WhenSuccessful_ClearsErrorMessage() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "sketch"
        sut.errorMessage = "Previous error"
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertNil(sut.errorMessage, "Should clear error message on success")
    }
    
    func testGeneratePortrait_WhenSuccessful_SetsIsLoadingToFalse() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "portrait"
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertFalse(sut.isLoading, "Should set isLoading to false after completion")
    }

    
    // MARK: - Generate Portrait Validation Tests
    
    func testGeneratePortrait_WithoutSelectedImage_SetsErrorMessage() async {
        // Given
        sut.selectedImage = nil
        sut.stylePrompt = "watercolor"
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertNotNil(sut.errorMessage, "Should set error message when no image selected")
        XCTAssertNil(sut.generatedPortrait, "Should not generate portrait without image")
    }
    
    func testGeneratePortrait_WithEmptyStylePrompt_SetsErrorMessage() async {
        // Given
        let testImage = createTestImage()
        sut.selectedImage = testImage
        sut.stylePrompt = ""
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertNotNil(sut.errorMessage, "Should set error message when style prompt is empty")
        XCTAssertNil(sut.generatedPortrait, "Should not generate portrait without style prompt")
    }
    
    func testGeneratePortrait_WithoutImageAndPrompt_DoesNotCallAPIService() async {
        // Given
        sut.selectedImage = nil
        sut.stylePrompt = ""
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertFalse(mockAPIService.generatePortraitCalled, "Should not call API service without required inputs")
    }
    
    // MARK: - Generate Portrait Error Handling Tests (Requirements 13.2, 13.4, 13.5)
    
    func testGeneratePortrait_WhenAPIError_SetsErrorMessage() async {
        // Given
        let testImage = createTestImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "watercolor"
        mockAPIService.generatePortraitResult = .failure(APIError.apiError(code: 500, message: "Server error"))
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertNotNil(sut.errorMessage, "Should set error message on API error")
    }
    
    func testGeneratePortrait_WhenNetworkError_SetsErrorMessage() async {
        // Given
        let testImage = createTestImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "oil painting"
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        mockAPIService.generatePortraitResult = .failure(APIError.networkError(networkError))
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertNotNil(sut.errorMessage, "Should set error message on network error")
    }
    
    func testGeneratePortrait_WhenError_PreservesSelectedImage() async {
        // Given
        let testImage = createTestImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "cartoon"
        mockAPIService.generatePortraitResult = .failure(APIError.apiError(code: 400, message: "Bad request"))
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertNotNil(sut.selectedImage, "Should preserve selected image on error")
    }
    
    func testGeneratePortrait_WhenError_PreservesStylePrompt() async {
        // Given
        let testImage = createTestImage()
        let stylePrompt = "sketch style"
        sut.selectedImage = testImage
        sut.stylePrompt = stylePrompt
        mockAPIService.generatePortraitResult = .failure(APIError.apiError(code: 400, message: "Bad request"))
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertEqual(sut.stylePrompt, stylePrompt, "Should preserve style prompt on error")
    }
    
    func testGeneratePortrait_WhenError_SetsIsLoadingToFalse() async {
        // Given
        let testImage = createTestImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "portrait"
        mockAPIService.generatePortraitResult = .failure(APIError.networkError(NSError(domain: "", code: 0)))
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertFalse(sut.isLoading, "Should set isLoading to false after error")
    }
    
    func testGeneratePortrait_WhenError_AllowsRetry() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "watercolor"
        
        // First call fails
        mockAPIService.generatePortraitResult = .failure(APIError.apiError(code: 500, message: "Server error"))
        await sut.generatePortrait()
        
        XCTAssertNotNil(sut.errorMessage, "Should have error message after failure")
        XCTAssertFalse(sut.isLoading, "Should not be loading after failure")
        
        // Second call succeeds (retry)
        mockAPIService.generatePortraitResult = .success(generatedImage)
        await sut.generatePortrait()
        
        // Then
        XCTAssertNotNil(sut.generatedPortrait, "Should be able to retry and succeed")
        XCTAssertNil(sut.errorMessage, "Should clear error message on successful retry")
    }

    
    // MARK: - Loading State Tests (Requirements 7.1, 7.2)
    
    func testGeneratePortrait_SetsIsLoadingToTrueDuringAPICall() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "watercolor"
        
        var loadingStatesDuringCall: [Bool] = []
        mockAPIService.onGeneratePortrait = { [weak self] in
            loadingStatesDuringCall.append(self?.sut.isLoading ?? false)
        }
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertTrue(loadingStatesDuringCall.contains(true), "isLoading should be true during API call")
    }
    
    func testGeneratePortrait_IsLoadingFalseBeforeCall() {
        // Then
        XCTAssertFalse(sut.isLoading, "isLoading should be false before any API call")
    }
    
    func testGeneratePortrait_IsLoadingFalseAfterSuccessfulCall() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "oil painting"
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertFalse(sut.isLoading, "isLoading should be false after successful call")
    }
    
    func testGeneratePortrait_IsLoadingFalseAfterFailedCall() async {
        // Given
        let testImage = createTestImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "cartoon"
        mockAPIService.generatePortraitResult = .failure(APIError.networkError(NSError(domain: "", code: 0)))
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertFalse(sut.isLoading, "isLoading should be false after failed call")
    }
    
    // MARK: - Refresh Portrait Tests (Requirements 8.1, 8.2)
    
    func testRefreshPortrait_UsesSameImage() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        let newGeneratedImage = createGeneratedImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "watercolor"
        
        // First generate
        mockAPIService.generatePortraitResult = .success(generatedImage)
        await sut.generatePortrait()
        mockAPIService.capturedImage = nil
        
        // When - refresh
        mockAPIService.generatePortraitResult = .success(newGeneratedImage)
        await sut.refreshPortrait()
        
        // Then
        XCTAssertNotNil(mockAPIService.capturedImage, "Should call API with image on refresh")
    }
    
    func testRefreshPortrait_UsesSameStylePrompt() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        let newGeneratedImage = createGeneratedImage()
        let stylePrompt = "oil painting style"
        sut.selectedImage = testImage
        sut.stylePrompt = stylePrompt
        
        // First generate
        mockAPIService.generatePortraitResult = .success(generatedImage)
        await sut.generatePortrait()
        mockAPIService.capturedStylePrompt = nil
        
        // When - refresh
        mockAPIService.generatePortraitResult = .success(newGeneratedImage)
        await sut.refreshPortrait()
        
        // Then
        XCTAssertEqual(mockAPIService.capturedStylePrompt, stylePrompt, "Should use same style prompt on refresh")
    }
    
    func testRefreshPortrait_UpdatesGeneratedPortrait() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        let newGeneratedImage = createGeneratedImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "cartoon"
        
        // First generate
        mockAPIService.generatePortraitResult = .success(generatedImage)
        await sut.generatePortrait()
        XCTAssertNotNil(sut.generatedPortrait, "Should have initial portrait")
        
        // When - refresh
        mockAPIService.generatePortraitResult = .success(newGeneratedImage)
        await sut.refreshPortrait()
        
        // Then
        XCTAssertNotNil(sut.generatedPortrait, "Should have generated portrait after refresh")
    }
    
    func testRefreshPortrait_WithoutSelectedImage_DoesNotCallAPI() async {
        // Given
        sut.selectedImage = nil
        sut.stylePrompt = "watercolor"
        
        // When
        await sut.refreshPortrait()
        
        // Then
        XCTAssertFalse(mockAPIService.generatePortraitCalled, "Should not call API without selected image")
    }
    
    func testRefreshPortrait_WithEmptyStylePrompt_DoesNotCallAPI() async {
        // Given
        let testImage = createTestImage()
        sut.selectedImage = testImage
        sut.stylePrompt = ""
        
        // When
        await sut.refreshPortrait()
        
        // Then
        XCTAssertFalse(mockAPIService.generatePortraitCalled, "Should not call API with empty style prompt")
    }
    
    func testRefreshPortrait_SetsIsLoadingDuringCall() async {
        // Given
        let testImage = createTestImage()
        let generatedImage = createGeneratedImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "sketch"
        
        var loadingStatesDuringCall: [Bool] = []
        mockAPIService.onGeneratePortrait = { [weak self] in
            loadingStatesDuringCall.append(self?.sut.isLoading ?? false)
        }
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // When
        await sut.refreshPortrait()
        
        // Then
        XCTAssertTrue(loadingStatesDuringCall.contains(true), "isLoading should be true during refresh")
    }
    
    func testRefreshPortrait_WhenError_PreservesInputs() async {
        // Given
        let testImage = createTestImage()
        let stylePrompt = "portrait style"
        sut.selectedImage = testImage
        sut.stylePrompt = stylePrompt
        mockAPIService.generatePortraitResult = .failure(APIError.networkError(NSError(domain: "", code: 0)))
        
        // When
        await sut.refreshPortrait()
        
        // Then
        XCTAssertNotNil(sut.selectedImage, "Should preserve selected image on refresh error")
        XCTAssertEqual(sut.stylePrompt, stylePrompt, "Should preserve style prompt on refresh error")
    }

    
    // MARK: - Save Portrait Tests (Requirement 9.2)
    
    func testSavePortrait_WithGeneratedPortrait_CallsImageService() async {
        // Given
        let generatedImage = createGeneratedImage()
        sut.generatedPortrait = generatedImage
        mockImageService.saveResult = .success(())
        
        // When
        sut.savePortrait()
        
        // Wait for async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertTrue(mockImageService.saveToPhotoLibraryCalled, "Should call ImageService.saveToPhotoLibrary")
    }
    
    func testSavePortrait_WithGeneratedPortrait_PassesCorrectImage() async {
        // Given
        let generatedImage = createGeneratedImage()
        sut.generatedPortrait = generatedImage
        mockImageService.saveResult = .success(())
        
        // When
        sut.savePortrait()
        
        // Wait for async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNotNil(mockImageService.capturedImage, "Should pass image to ImageService")
    }
    
    func testSavePortrait_WithoutGeneratedPortrait_SetsErrorMessage() {
        // Given
        sut.generatedPortrait = nil
        
        // When
        sut.savePortrait()
        
        // Then
        XCTAssertNotNil(sut.errorMessage, "Should set error message when no portrait to save")
    }
    
    func testSavePortrait_WithoutGeneratedPortrait_DoesNotCallImageService() {
        // Given
        sut.generatedPortrait = nil
        
        // When
        sut.savePortrait()
        
        // Then
        XCTAssertFalse(mockImageService.saveToPhotoLibraryCalled, "Should not call ImageService without portrait")
    }
    
    func testSavePortrait_WhenImageServiceFails_SetsErrorMessage() async {
        // Given
        let generatedImage = createGeneratedImage()
        sut.generatedPortrait = generatedImage
        mockImageService.saveResult = .failure(PermissionError.photoLibraryAccessDenied)
        
        // When
        sut.savePortrait()
        
        // Wait for async task to complete
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Then
        XCTAssertNotNil(sut.errorMessage, "Should set error message when save fails")
    }
    
    // MARK: - Share Portrait Tests (Requirement 10.1)
    
    func testSharePortrait_WithGeneratedPortrait_ReturnsArrayWithImage() {
        // Given
        let generatedImage = createGeneratedImage()
        sut.generatedPortrait = generatedImage
        
        // When
        let shareItems = sut.sharePortrait()
        
        // Then
        XCTAssertEqual(shareItems.count, 1, "Should return array with one item")
        XCTAssertTrue(shareItems.first is UIImage, "Should return UIImage in array")
    }
    
    func testSharePortrait_WithGeneratedPortrait_ReturnsCorrectImage() {
        // Given
        let generatedImage = createGeneratedImage()
        sut.generatedPortrait = generatedImage
        
        // When
        let shareItems = sut.sharePortrait()
        
        // Then
        let sharedImage = shareItems.first as? UIImage
        XCTAssertNotNil(sharedImage, "Should return the generated portrait")
    }
    
    func testSharePortrait_WithoutGeneratedPortrait_ReturnsEmptyArray() {
        // Given
        sut.generatedPortrait = nil
        
        // When
        let shareItems = sut.sharePortrait()
        
        // Then
        XCTAssertTrue(shareItems.isEmpty, "Should return empty array when no portrait")
    }
    
    // MARK: - Error Message Tests
    
    func testGeneratePortrait_APIError_DisplaysLocalizedMessage() async {
        // Given
        let testImage = createTestImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "watercolor"
        let errorMessage = "Custom API error message"
        mockAPIService.generatePortraitResult = .failure(APIError.apiError(code: 400, message: errorMessage))
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertEqual(sut.errorMessage, errorMessage, "Should display localized error message from API")
    }
    
    func testGeneratePortrait_NetworkError_DisplaysUserFriendlyMessage() async {
        // Given
        let testImage = createTestImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "oil painting"
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        mockAPIService.generatePortraitResult = .failure(APIError.networkError(networkError))
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
        XCTAssertTrue(sut.errorMessage!.contains("internet") || sut.errorMessage!.contains("connect"), "Should display user-friendly network error message")
    }
    
    func testGeneratePortrait_ImageConversionError_DisplaysUserFriendlyMessage() async {
        // Given
        let testImage = createTestImage()
        sut.selectedImage = testImage
        sut.stylePrompt = "cartoon"
        mockAPIService.generatePortraitResult = .failure(APIError.imageConversionError)
        
        // When
        await sut.generatePortrait()
        
        // Then
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
        XCTAssertTrue(sut.errorMessage!.contains("image") || sut.errorMessage!.contains("process"), "Should display user-friendly image error message")
    }
}



// MARK: - Mock Classes

class MockAPIService: APIServiceProtocol {
    var generatePortraitCalled = false
    var capturedImage: UIImage?
    var capturedStylePrompt: String?
    var generatePortraitResult: Result<UIImage, Error> = .failure(APIError.invalidResponse)
    var onGeneratePortrait: (() -> Void)?
    
    func generatePortrait(image: UIImage, stylePrompt: String) async throws -> UIImage {
        generatePortraitCalled = true
        capturedImage = image
        capturedStylePrompt = stylePrompt
        onGeneratePortrait?()
        
        switch generatePortraitResult {
        case .success(let image):
            return image
        case .failure(let error):
            throw error
        }
    }
}

class MockImageService: ImageServiceProtocol {
    var saveToPhotoLibraryCalled = false
    var capturedImage: UIImage?
    var saveResult: Result<Void, Error> = .success(())
    
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        saveToPhotoLibraryCalled = true
        capturedImage = image
        
        switch saveResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}

class MockPermissionService: PermissionServiceProtocol {
    var cameraPermissionStatus: PermissionStatus = .authorized
    var photoLibraryPermissionStatus: PermissionStatus = .authorized
    var requestCameraPermissionResult = true
    var requestPhotoLibraryPermissionResult = true
    
    func checkCameraPermission() -> PermissionStatus {
        return cameraPermissionStatus
    }
    
    func requestCameraPermission() async -> Bool {
        return requestCameraPermissionResult
    }
    
    func checkPhotoLibraryPermission() -> PermissionStatus {
        return photoLibraryPermissionStatus
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        return requestPhotoLibraryPermissionResult
    }
}
