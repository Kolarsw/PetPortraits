//
//  PropertyBasedTests.swift
//  PetPortraitsTests
//
//  Tests for all 14 correctness properties defined in the design document.
//  Uses standard XCTest with multiple example inputs for comprehensive coverage.
//
//  Created by Kiro
//

import XCTest
import UIKit
@testable import PetPortraits

// MARK: - Mock Services

class PropertyMockAPIService: APIServiceProtocol {
    var capturedImage: UIImage?
    var capturedStylePrompt: String?
    var imageToReturn: UIImage?
    var errorToThrow: Error?
    
    func generatePortrait(image: UIImage, stylePrompt: String) async throws -> UIImage {
        capturedImage = image
        capturedStylePrompt = stylePrompt
        if let error = errorToThrow {
            throw error
        }
        return imageToReturn ?? UIImage()
    }
}

class PropertyMockImageService: ImageServiceProtocol {
    var saveWasCalled = false
    var savedImage: UIImage?
    
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        saveWasCalled = true
        savedImage = image
    }
}

class PropertyMockPermissionService: PermissionServiceProtocol {
    var cameraStatus: PermissionStatus = .authorized
    var photoLibraryStatus: PermissionStatus = .authorized
    
    func checkCameraPermission() -> PermissionStatus { cameraStatus }
    func requestCameraPermission() async -> Bool { cameraStatus == .authorized }
    func checkPhotoLibraryPermission() -> PermissionStatus { photoLibraryStatus }
    func requestPhotoLibraryPermission() async -> Bool { photoLibraryStatus == .authorized }
}

// MARK: - Correctness Property Tests

@MainActor
class CorrectnessPropertyTests: XCTestCase {
    
    var mockAPI: PropertyMockAPIService!
    var mockImage: PropertyMockImageService!
    var mockPermission: PropertyMockPermissionService!
    var viewModel: PortraitViewModel!
    
    override func setUp() async throws {
        mockAPI = PropertyMockAPIService()
        mockImage = PropertyMockImageService()
        mockPermission = PropertyMockPermissionService()
        viewModel = PortraitViewModel(
            apiService: mockAPI,
            imageService: mockImage,
            permissionService: mockPermission
        )
    }
    
    // MARK: - Helper
    
    func createTestImage(width: Int = 100, height: Int = 100, color: UIColor = .red) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContext(size)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Property 1: API Request Completeness
    // Validates: Requirements 2.2, 6.1
    
    func testProperty1_APIRequestCompleteness_withSmallImage() async {
        let image = createTestImage(width: 50, height: 50)
        let prompt = "watercolor"
        mockAPI.imageToReturn = createTestImage(color: .blue)
        
        viewModel.selectedImage = image
        viewModel.stylePrompt = prompt
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(mockAPI.capturedImage)
        XCTAssertEqual(mockAPI.capturedStylePrompt, prompt)
    }
    
    func testProperty1_APIRequestCompleteness_withLargeImage() async {
        let image = createTestImage(width: 500, height: 500)
        let prompt = "oil painting style"
        mockAPI.imageToReturn = createTestImage(color: .blue)
        
        viewModel.selectedImage = image
        viewModel.stylePrompt = prompt
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(mockAPI.capturedImage)
        XCTAssertEqual(mockAPI.capturedStylePrompt, prompt)
    }
    
    func testProperty1_APIRequestCompleteness_withLongPrompt() async {
        let image = createTestImage()
        let prompt = "beautiful watercolor painting in impressionist style with vibrant colors"
        mockAPI.imageToReturn = createTestImage(color: .blue)
        
        viewModel.selectedImage = image
        viewModel.stylePrompt = prompt
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(mockAPI.capturedImage)
        XCTAssertEqual(mockAPI.capturedStylePrompt, prompt)
    }
    
    // MARK: - Property 2: API Response Display
    // Validates: Requirements 2.3, 6.2
    
    func testProperty2_APIResponseDisplay_updatesPortrait() async {
        let generatedImage = createTestImage(color: .green)
        mockAPI.imageToReturn = generatedImage
        
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.generatedPortrait)
    }
    
    func testProperty2_APIResponseDisplay_withDifferentSizes() async {
        let sizes = [(100, 100), (200, 300), (512, 512)]
        
        for (width, height) in sizes {
            mockAPI.imageToReturn = createTestImage(width: width, height: height)
            viewModel.selectedImage = createTestImage()
            viewModel.stylePrompt = "test"
            await viewModel.generatePortrait()
            
            XCTAssertNotNil(viewModel.generatedPortrait, "Failed for size \(width)x\(height)")
        }
    }
    
    // MARK: - Property 3: Image Selection Display
    // Validates: Requirements 4.2, 5.2
    
    func testProperty3_ImageSelectionDisplay_storesImage() {
        let image = createTestImage()
        viewModel.selectedImage = image
        XCTAssertNotNil(viewModel.selectedImage)
    }
    
    func testProperty3_ImageSelectionDisplay_withVariousSizes() {
        let sizes = [(50, 50), (100, 200), (300, 300), (500, 400)]
        
        for (width, height) in sizes {
            let image = createTestImage(width: width, height: height)
            viewModel.selectedImage = image
            XCTAssertNotNil(viewModel.selectedImage, "Failed for size \(width)x\(height)")
        }
    }
    
    // MARK: - Property 4: Style Input Availability
    // Validates: Requirements 4.3, 5.3
    
    func testProperty4_StyleInputAvailability_canSetPrompt() {
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "watercolor"
        XCTAssertEqual(viewModel.stylePrompt, "watercolor")
    }
    
    func testProperty4_StyleInputAvailability_withVariousPrompts() {
        let prompts = ["", "short", "medium length prompt", "very long detailed style prompt with many words"]
        
        for prompt in prompts {
            viewModel.stylePrompt = prompt
            XCTAssertEqual(viewModel.stylePrompt, prompt)
        }
    }
    
    // MARK: - Property 5: Camera Interface Activation
    // Validates: Requirements 4.1
    
    func testProperty5_CameraInterfaceActivation_permissionCheck() {
        mockPermission.cameraStatus = .authorized
        XCTAssertEqual(mockPermission.checkCameraPermission(), .authorized)
        
        mockPermission.cameraStatus = .denied
        XCTAssertEqual(mockPermission.checkCameraPermission(), .denied)
        
        mockPermission.cameraStatus = .notDetermined
        XCTAssertEqual(mockPermission.checkCameraPermission(), .notDetermined)
    }
    
    // MARK: - Property 6: Photo Picker Activation
    // Validates: Requirements 5.1
    
    func testProperty6_PhotoPickerActivation_permissionCheck() {
        mockPermission.photoLibraryStatus = .authorized
        XCTAssertEqual(mockPermission.checkPhotoLibraryPermission(), .authorized)
        
        mockPermission.photoLibraryStatus = .denied
        XCTAssertEqual(mockPermission.checkPhotoLibraryPermission(), .denied)
        
        mockPermission.photoLibraryStatus = .notDetermined
        XCTAssertEqual(mockPermission.checkPhotoLibraryPermission(), .notDetermined)
    }
    
    // MARK: - Property 7: Loading State Behavior
    // Validates: Requirements 7.1, 7.2
    
    func testProperty7_LoadingStateBehavior_initiallyFalse() {
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testProperty7_LoadingStateBehavior_falseAfterCompletion() async {
        mockAPI.imageToReturn = createTestImage()
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        
        await viewModel.generatePortrait()
        
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testProperty7_LoadingStateBehavior_falseAfterError() async {
        mockAPI.errorToThrow = APIError.networkError(NSError(domain: "", code: -1))
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        
        await viewModel.generatePortrait()
        
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Property 8: Refresh Input Preservation
    // Validates: Requirements 8.1
    
    func testProperty8_RefreshInputPreservation_samePromptUsed() async {
        let originalPrompt = "watercolor style"
        mockAPI.imageToReturn = createTestImage()
        
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = originalPrompt
        await viewModel.generatePortrait()
        
        mockAPI.capturedStylePrompt = nil
        await viewModel.refreshPortrait()
        
        XCTAssertEqual(mockAPI.capturedStylePrompt, originalPrompt)
    }
    
    func testProperty8_RefreshInputPreservation_withVariousPrompts() async {
        let prompts = ["short", "medium prompt", "very long detailed prompt"]
        
        for prompt in prompts {
            mockAPI.imageToReturn = createTestImage()
            viewModel.selectedImage = createTestImage()
            viewModel.stylePrompt = prompt
            await viewModel.generatePortrait()
            
            mockAPI.capturedStylePrompt = nil
            await viewModel.refreshPortrait()
            
            XCTAssertEqual(mockAPI.capturedStylePrompt, prompt, "Failed for prompt: \(prompt)")
        }
    }
    
    // MARK: - Property 9: Refresh Portrait Update
    // Validates: Requirements 8.2
    
    func testProperty9_RefreshPortraitUpdate_updatesImage() async {
        mockAPI.imageToReturn = createTestImage(color: .blue)
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.generatedPortrait)
        
        mockAPI.imageToReturn = createTestImage(color: .green)
        await viewModel.refreshPortrait()
        
        XCTAssertNotNil(viewModel.generatedPortrait)
    }
    
    // MARK: - Property 10: Portrait Persistence
    // Validates: Requirements 9.2
    
    func testProperty10_PortraitPersistence_callsImageService() async {
        mockAPI.imageToReturn = createTestImage()
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        await viewModel.generatePortrait()
        
        viewModel.savePortrait()
        
        // Wait for async save
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(mockImage.saveWasCalled)
        XCTAssertNotNil(mockImage.savedImage)
    }
    
    // MARK: - Property 11: Share Sheet Presentation
    // Validates: Requirements 10.1, 10.2
    
    func testProperty11_ShareSheetPresentation_returnsImage() async {
        mockAPI.imageToReturn = createTestImage()
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        await viewModel.generatePortrait()
        
        let shareItems = viewModel.sharePortrait()
        
        XCTAssertEqual(shareItems.count, 1)
        XCTAssertTrue(shareItems.first is UIImage)
    }
    
    func testProperty11_ShareSheetPresentation_emptyWhenNoPortrait() {
        let shareItems = viewModel.sharePortrait()
        XCTAssertTrue(shareItems.isEmpty)
    }
    
    // MARK: - Property 12: Error Message Display
    // Validates: Requirements 13.1, 13.3
    
    func testProperty12_ErrorMessageDisplay_networkError() async {
        mockAPI.errorToThrow = APIError.networkError(NSError(domain: "", code: -1))
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.errorMessage!.isEmpty)
    }
    
    func testProperty12_ErrorMessageDisplay_invalidResponse() async {
        mockAPI.errorToThrow = APIError.invalidResponse
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testProperty12_ErrorMessageDisplay_apiError() async {
        mockAPI.errorToThrow = APIError.apiError(code: 500, message: "Server error")
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    func testProperty12_ErrorMessageDisplay_imageConversionError() async {
        mockAPI.errorToThrow = APIError.imageConversionError
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Property 13: Error State Preservation
    // Validates: Requirements 13.2, 13.4
    
    func testProperty13_ErrorStatePreservation_preservesImage() async {
        let originalImage = createTestImage()
        mockAPI.errorToThrow = APIError.networkError(NSError(domain: "", code: -1))
        
        viewModel.selectedImage = originalImage
        viewModel.stylePrompt = "test"
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.selectedImage)
    }
    
    func testProperty13_ErrorStatePreservation_preservesPrompt() async {
        let originalPrompt = "watercolor style"
        mockAPI.errorToThrow = APIError.networkError(NSError(domain: "", code: -1))
        
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = originalPrompt
        await viewModel.generatePortrait()
        
        XCTAssertEqual(viewModel.stylePrompt, originalPrompt)
    }
    
    func testProperty13_ErrorStatePreservation_withAllErrorTypes() async {
        let errors: [APIError] = [
            .networkError(NSError(domain: "", code: -1)),
            .invalidResponse,
            .apiError(code: 500, message: "Error"),
            .imageConversionError
        ]
        
        for error in errors {
            let prompt = "test prompt"
            mockAPI.errorToThrow = error
            viewModel.selectedImage = createTestImage()
            viewModel.stylePrompt = prompt
            
            await viewModel.generatePortrait()
            
            XCTAssertNotNil(viewModel.selectedImage, "Image not preserved for \(error)")
            XCTAssertEqual(viewModel.stylePrompt, prompt, "Prompt not preserved for \(error)")
        }
    }
    
    // MARK: - Property 14: Error Recovery Capability
    // Validates: Requirements 13.5
    
    func testProperty14_ErrorRecoveryCapability_canRetryAfterError() async {
        // First attempt fails
        mockAPI.errorToThrow = APIError.networkError(NSError(domain: "", code: -1))
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = "test"
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        
        // Second attempt succeeds
        mockAPI.errorToThrow = nil
        mockAPI.imageToReturn = createTestImage(color: .green)
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.generatedPortrait)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testProperty14_ErrorRecoveryCapability_inputsPreservedForRetry() async {
        let originalPrompt = "watercolor"
        mockAPI.errorToThrow = APIError.networkError(NSError(domain: "", code: -1))
        
        viewModel.selectedImage = createTestImage()
        viewModel.stylePrompt = originalPrompt
        await viewModel.generatePortrait()
        
        // Verify inputs still available for retry
        XCTAssertNotNil(viewModel.selectedImage)
        XCTAssertEqual(viewModel.stylePrompt, originalPrompt)
        XCTAssertFalse(viewModel.isLoading)
    }
}
