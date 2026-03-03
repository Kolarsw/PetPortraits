//
//  IntegrationTests.swift
//  PetPortraitsTests
//
//  Created by Kiro
//
//  Integration tests for end-to-end workflows
//  These tests verify complete user workflows using mocked services
//

import XCTest
import UIKit
@testable import PetPortraits

/// Integration tests for end-to-end workflows
/// Validates complete user journeys through the app with mocked services
@MainActor
class IntegrationTests: XCTestCase {
    
    var viewModel: PortraitViewModel!
    var mockAPIService: MockAPIServiceForIntegration!
    var mockImageService: MockImageServiceForIntegration!
    var mockPermissionService: MockPermissionServiceForIntegration!
    
    override func setUp() {
        super.setUp()
        mockAPIService = MockAPIServiceForIntegration()
        mockImageService = MockImageServiceForIntegration()
        mockPermissionService = MockPermissionServiceForIntegration()
        viewModel = PortraitViewModel(
            apiService: mockAPIService,
            imageService: mockImageService,
            permissionService: mockPermissionService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockAPIService = nil
        mockImageService = nil
        mockPermissionService = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(color: UIColor = .red, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        UIGraphicsBeginImageContext(size)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    private func createGeneratedImage() -> UIImage {
        return createTestImage(color: .blue, size: CGSize(width: 512, height: 512))
    }
    
    // MARK: - 14.1 Happy Path: Photo Selection to Save
    // Test complete flow: launch → select photo → enter prompt → generate → view results → save
    // Requirements: 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 9.1, 9.2
    
    func testHappyPath_PhotoSelectionToSave_CompleteFlow() async {
        // Given - Initial state (simulating app launch)
        XCTAssertNil(viewModel.selectedImage, "Initial state: no image selected")
        XCTAssertEqual(viewModel.stylePrompt, "", "Initial state: empty style prompt")
        XCTAssertNil(viewModel.generatedPortrait, "Initial state: no generated portrait")
        XCTAssertFalse(viewModel.isLoading, "Initial state: not loading")
        
        // Step 1: Select photo from gallery (simulating PhotoPicker selection)
        // Requirements: 5.1, 5.2
        let selectedPhoto = createTestImage()
        viewModel.selectedImage = selectedPhoto
        
        XCTAssertNotNil(viewModel.selectedImage, "Photo should be selected")
        
        // Step 2: Enter style prompt
        // Requirements: 5.3
        let stylePrompt = "watercolor painting style"
        viewModel.stylePrompt = stylePrompt
        
        XCTAssertEqual(viewModel.stylePrompt, stylePrompt, "Style prompt should be set")
        
        // Step 3: Generate portrait
        // Requirements: 6.1, 6.2
        let generatedImage = createGeneratedImage()
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        await viewModel.generatePortrait()
        
        // Verify API was called with correct inputs
        XCTAssertTrue(mockAPIService.generatePortraitCalled, "API should be called")
        XCTAssertNotNil(mockAPIService.capturedImage, "API should receive image")
        XCTAssertEqual(mockAPIService.capturedStylePrompt, stylePrompt, "API should receive style prompt")
        
        // Verify portrait was generated
        // Requirements: 6.2, 6.3
        XCTAssertNotNil(viewModel.generatedPortrait, "Portrait should be generated")
        XCTAssertFalse(viewModel.isLoading, "Loading should be complete")
        XCTAssertNil(viewModel.errorMessage, "No error should occur")
        
        // Step 4: Save portrait
        // Requirements: 9.1, 9.2
        mockImageService.saveResult = .success(())
        viewModel.savePortrait()
        
        // Wait for async save operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(mockImageService.saveToPhotoLibraryCalled, "Save should be called")
        XCTAssertNotNil(mockImageService.capturedImage, "Image should be passed to save")
    }
    
    func testHappyPath_PhotoSelectionToSave_VerifiesStateTransitions() async {
        // Given
        let selectedPhoto = createTestImage()
        let generatedImage = createGeneratedImage()
        mockAPIService.generatePortraitResult = .success(generatedImage)
        mockImageService.saveResult = .success(())
        
        // Track state transitions
        var stateHistory: [(isLoading: Bool, hasPortrait: Bool, hasError: Bool)] = []
        
        // Record initial state
        stateHistory.append((viewModel.isLoading, viewModel.generatedPortrait != nil, viewModel.errorMessage != nil))
        
        // Select photo
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "oil painting"
        
        // Capture loading state during API call
        mockAPIService.onGeneratePortrait = { [weak self] in
            guard let self = self else { return }
            stateHistory.append((self.viewModel.isLoading, self.viewModel.generatedPortrait != nil, self.viewModel.errorMessage != nil))
        }
        
        // Generate
        await viewModel.generatePortrait()
        
        // Record final state
        stateHistory.append((viewModel.isLoading, viewModel.generatedPortrait != nil, viewModel.errorMessage != nil))
        
        // Verify state transitions
        XCTAssertFalse(stateHistory[0].isLoading, "Initial: not loading")
        XCTAssertFalse(stateHistory[0].hasPortrait, "Initial: no portrait")
        
        // During API call
        XCTAssertTrue(stateHistory[1].isLoading, "During API: loading")
        
        // After completion
        XCTAssertFalse(stateHistory[2].isLoading, "Final: not loading")
        XCTAssertTrue(stateHistory[2].hasPortrait, "Final: has portrait")
        XCTAssertFalse(stateHistory[2].hasError, "Final: no error")
    }
    
    func testHappyPath_PhotoSelectionToSave_UIUpdatesCorrectly() async {
        // Given
        let selectedPhoto = createTestImage()
        let generatedImage = createGeneratedImage()
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // When - Complete flow
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "cartoon style"
        await viewModel.generatePortrait()
        
        // Then - Verify UI-relevant state
        XCTAssertNotNil(viewModel.selectedImage, "Selected image should persist for display")
        XCTAssertNotNil(viewModel.generatedPortrait, "Generated portrait should be available for display")
        XCTAssertFalse(viewModel.isLoading, "Loading indicator should be hidden")
        XCTAssertNil(viewModel.errorMessage, "Error alert should not be shown")
    }
}


// MARK: - 14.2 Happy Path: Camera Capture to Share
// Test complete flow: launch → take photo → enter prompt → generate → view results → share
// Requirements: 4.1, 4.2, 4.3, 6.1, 6.2, 6.3, 10.1, 10.2, 10.3

extension IntegrationTests {
    
    func testHappyPath_CameraCaptureToShare_CompleteFlow() async {
        // Given - Initial state (simulating app launch)
        XCTAssertNil(viewModel.selectedImage, "Initial state: no image captured")
        XCTAssertEqual(viewModel.stylePrompt, "", "Initial state: empty style prompt")
        XCTAssertNil(viewModel.generatedPortrait, "Initial state: no generated portrait")
        
        // Step 1: Capture photo with camera (simulating CameraViewController capture)
        // Requirements: 4.1, 4.2
        let capturedPhoto = createTestImage(color: .green)
        viewModel.selectedImage = capturedPhoto
        
        XCTAssertNotNil(viewModel.selectedImage, "Photo should be captured")
        
        // Step 2: Enter style prompt
        // Requirements: 4.3
        let stylePrompt = "renaissance portrait style"
        viewModel.stylePrompt = stylePrompt
        
        XCTAssertEqual(viewModel.stylePrompt, stylePrompt, "Style prompt should be set")
        
        // Step 3: Generate portrait
        // Requirements: 6.1, 6.2
        let generatedImage = createGeneratedImage()
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        await viewModel.generatePortrait()
        
        // Verify API was called correctly
        XCTAssertTrue(mockAPIService.generatePortraitCalled, "API should be called")
        XCTAssertNotNil(mockAPIService.capturedImage, "API should receive captured image")
        XCTAssertEqual(mockAPIService.capturedStylePrompt, stylePrompt, "API should receive style prompt")
        
        // Verify portrait was generated
        // Requirements: 6.2, 6.3
        XCTAssertNotNil(viewModel.generatedPortrait, "Portrait should be generated")
        XCTAssertFalse(viewModel.isLoading, "Loading should be complete")
        
        // Step 4: Share portrait
        // Requirements: 10.1, 10.2, 10.3
        let shareItems = viewModel.sharePortrait()
        
        XCTAssertEqual(shareItems.count, 1, "Share items should contain one item")
        XCTAssertTrue(shareItems.first is UIImage, "Share item should be UIImage")
    }
    
    func testHappyPath_CameraCaptureToShare_ShareContainsGeneratedPortrait() async {
        // Given
        let capturedPhoto = createTestImage()
        let generatedImage = createGeneratedImage()
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // When - Complete flow
        viewModel.selectedImage = capturedPhoto
        viewModel.stylePrompt = "pop art style"
        await viewModel.generatePortrait()
        
        // Then - Verify share functionality
        let shareItems = viewModel.sharePortrait()
        
        XCTAssertFalse(shareItems.isEmpty, "Share items should not be empty")
        
        // Verify the shared image is the generated portrait
        guard let sharedImage = shareItems.first as? UIImage else {
            XCTFail("Share item should be UIImage")
            return
        }
        
        // Compare image sizes to verify it's the generated portrait
        XCTAssertEqual(sharedImage.size, generatedImage.size, "Shared image should be the generated portrait")
    }
    
    func testHappyPath_CameraCaptureToShare_VerifiesAllSteps() async {
        // Given
        let capturedPhoto = createTestImage()
        let generatedImage = createGeneratedImage()
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // Step 1: Verify camera capture simulation
        viewModel.selectedImage = capturedPhoto
        XCTAssertNotNil(viewModel.selectedImage, "Step 1: Camera capture successful")
        
        // Step 2: Verify style input
        viewModel.stylePrompt = "sketch style"
        XCTAssertFalse(viewModel.stylePrompt.isEmpty, "Step 2: Style prompt entered")
        
        // Step 3: Verify generation
        await viewModel.generatePortrait()
        XCTAssertNotNil(viewModel.generatedPortrait, "Step 3: Portrait generated")
        
        // Step 4: Verify share preparation
        let shareItems = viewModel.sharePortrait()
        XCTAssertEqual(shareItems.count, 1, "Step 4: Share items prepared")
    }
}

// MARK: - 14.3 Error Recovery Path
// Test flow: select photo → enter prompt → generate (network error) → retry → success
// Requirements: 13.1, 13.2, 13.3, 13.4, 13.5

extension IntegrationTests {
    
    func testErrorRecovery_NetworkErrorThenRetry_CompleteFlow() async {
        // Given - Setup initial state
        let selectedPhoto = createTestImage()
        let generatedImage = createGeneratedImage()
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "watercolor style"
        
        // Step 1: First attempt fails with network error
        // Requirements: 13.1, 13.3
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        mockAPIService.generatePortraitResult = .failure(APIError.networkError(networkError))
        
        await viewModel.generatePortrait()
        
        // Verify error state
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be displayed")
        XCTAssertTrue(viewModel.errorMessage!.contains("internet") || viewModel.errorMessage!.contains("connect"),
                      "Error message should be user-friendly")
        
        // Verify state preservation
        // Requirements: 13.2, 13.4
        XCTAssertNotNil(viewModel.selectedImage, "Selected image should be preserved")
        XCTAssertEqual(viewModel.stylePrompt, "watercolor style", "Style prompt should be preserved")
        XCTAssertFalse(viewModel.isLoading, "Loading should be complete")
        
        // Step 2: Retry succeeds
        // Requirements: 13.5
        mockAPIService.generatePortraitResult = .success(generatedImage)
        mockAPIService.generatePortraitCalled = false
        
        await viewModel.generatePortrait()
        
        // Verify successful retry
        XCTAssertTrue(mockAPIService.generatePortraitCalled, "API should be called on retry")
        XCTAssertNotNil(viewModel.generatedPortrait, "Portrait should be generated on retry")
        XCTAssertNil(viewModel.errorMessage, "Error message should be cleared on success")
    }
    
    func testErrorRecovery_APIErrorThenRetry_PreservesInputs() async {
        // Given
        let selectedPhoto = createTestImage()
        let generatedImage = createGeneratedImage()
        let stylePrompt = "oil painting style"
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = stylePrompt
        
        // Step 1: API error occurs
        mockAPIService.generatePortraitResult = .failure(APIError.apiError(code: 500, message: "Server error"))
        
        await viewModel.generatePortrait()
        
        // Verify inputs are preserved
        XCTAssertNotNil(viewModel.selectedImage, "Image preserved after API error")
        XCTAssertEqual(viewModel.stylePrompt, stylePrompt, "Style prompt preserved after API error")
        XCTAssertNotNil(viewModel.errorMessage, "Error message displayed")
        
        // Step 2: Retry with same inputs
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        await viewModel.generatePortrait()
        
        // Verify same inputs were used
        XCTAssertEqual(mockAPIService.capturedStylePrompt, stylePrompt, "Same style prompt used on retry")
        XCTAssertNotNil(viewModel.generatedPortrait, "Portrait generated on retry")
    }
    
    func testErrorRecovery_MultipleRetries_EventualSuccess() async {
        // Given
        let selectedPhoto = createTestImage()
        let generatedImage = createGeneratedImage()
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "cartoon style"
        
        // First attempt - network error
        mockAPIService.generatePortraitResult = .failure(APIError.networkError(NSError(domain: "", code: -1)))
        await viewModel.generatePortrait()
        XCTAssertNotNil(viewModel.errorMessage, "First error displayed")
        
        // Second attempt - API error
        mockAPIService.generatePortraitResult = .failure(APIError.apiError(code: 503, message: "Service unavailable"))
        await viewModel.generatePortrait()
        XCTAssertNotNil(viewModel.errorMessage, "Second error displayed")
        
        // Third attempt - success
        mockAPIService.generatePortraitResult = .success(generatedImage)
        await viewModel.generatePortrait()
        
        // Verify eventual success
        XCTAssertNotNil(viewModel.generatedPortrait, "Portrait generated after multiple retries")
        XCTAssertNil(viewModel.errorMessage, "Error cleared on success")
    }
    
    func testErrorRecovery_ErrorMessageIsLocalized() async {
        // Given
        let selectedPhoto = createTestImage()
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "portrait style"
        
        // Test network error message
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        mockAPIService.generatePortraitResult = .failure(APIError.networkError(networkError))
        
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.errorMessage, "Error message should exist")
        XCTAssertFalse(viewModel.errorMessage!.isEmpty, "Error message should not be empty")
        // Verify it's user-friendly (not a raw error code)
        XCTAssertFalse(viewModel.errorMessage!.contains("NSURLError"), "Error should be localized, not raw")
    }
    
    func testErrorRecovery_GenerateButtonEnabledAfterError() async {
        // Given
        let selectedPhoto = createTestImage()
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "sketch style"
        mockAPIService.generatePortraitResult = .failure(APIError.invalidResponse)
        
        // When - Error occurs
        await viewModel.generatePortrait()
        
        // Then - Verify retry is possible (isLoading is false, allowing button to be enabled)
        XCTAssertFalse(viewModel.isLoading, "Loading should be false to enable retry")
        XCTAssertNotNil(viewModel.selectedImage, "Image preserved for retry")
        XCTAssertFalse(viewModel.stylePrompt.isEmpty, "Style prompt preserved for retry")
    }
}


// MARK: - 14.4 Permission Handling
// Test flow: launch → take photo (no permission) → grant permission → take photo → success
// Requirements: 11.1, 11.2, 12.1, 12.2

extension IntegrationTests {
    
    func testPermissionHandling_CameraPermissionFlow() async {
        // Given - Camera permission not determined
        mockPermissionService.cameraPermissionStatus = .notDetermined
        mockPermissionService.requestCameraPermissionResult = true
        
        // Step 1: Check initial permission status
        let initialStatus = mockPermissionService.checkCameraPermission()
        XCTAssertEqual(initialStatus, .notDetermined, "Initial camera permission should be not determined")
        
        // Step 2: Request permission (simulating user granting access)
        let granted = await mockPermissionService.requestCameraPermission()
        XCTAssertTrue(granted, "Permission should be granted")
        
        // Step 3: After permission granted, simulate camera capture
        mockPermissionService.cameraPermissionStatus = .authorized
        let capturedPhoto = createTestImage()
        viewModel.selectedImage = capturedPhoto
        
        XCTAssertNotNil(viewModel.selectedImage, "Photo should be captured after permission granted")
        
        // Step 4: Complete the flow
        let generatedImage = createGeneratedImage()
        mockAPIService.generatePortraitResult = .success(generatedImage)
        viewModel.stylePrompt = "portrait style"
        
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.generatedPortrait, "Portrait should be generated after permission flow")
    }
    
    func testPermissionHandling_PhotoLibraryPermissionFlow() async {
        // Given - Photo library permission not determined
        mockPermissionService.photoLibraryPermissionStatus = .notDetermined
        mockPermissionService.requestPhotoLibraryPermissionResult = true
        
        // Step 1: Check initial permission status
        let initialStatus = mockPermissionService.checkPhotoLibraryPermission()
        XCTAssertEqual(initialStatus, .notDetermined, "Initial photo library permission should be not determined")
        
        // Step 2: Request permission (simulating user granting access)
        let granted = await mockPermissionService.requestPhotoLibraryPermission()
        XCTAssertTrue(granted, "Permission should be granted")
        
        // Step 3: After permission granted, simulate photo selection
        mockPermissionService.photoLibraryPermissionStatus = .authorized
        let selectedPhoto = createTestImage()
        viewModel.selectedImage = selectedPhoto
        
        XCTAssertNotNil(viewModel.selectedImage, "Photo should be selected after permission granted")
        
        // Step 4: Complete the flow
        let generatedImage = createGeneratedImage()
        mockAPIService.generatePortraitResult = .success(generatedImage)
        viewModel.stylePrompt = "watercolor style"
        
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.generatedPortrait, "Portrait should be generated after permission flow")
    }
    
    func testPermissionHandling_CameraPermissionDenied() async {
        // Given - Camera permission denied
        mockPermissionService.cameraPermissionStatus = .denied
        
        // When - Check permission status
        let status = mockPermissionService.checkCameraPermission()
        
        // Then - Verify denied status
        XCTAssertEqual(status, .denied, "Camera permission should be denied")
        
        // Verify app can still function with photo library
        mockPermissionService.photoLibraryPermissionStatus = .authorized
        let selectedPhoto = createTestImage()
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "sketch style"
        
        let generatedImage = createGeneratedImage()
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.generatedPortrait, "App should work with photo library when camera denied")
    }
    
    func testPermissionHandling_PhotoLibraryPermissionDenied() async {
        // Given - Photo library permission denied
        mockPermissionService.photoLibraryPermissionStatus = .denied
        
        // When - Check permission status
        let status = mockPermissionService.checkPhotoLibraryPermission()
        
        // Then - Verify denied status
        XCTAssertEqual(status, .denied, "Photo library permission should be denied")
        
        // Verify app can still function with camera
        mockPermissionService.cameraPermissionStatus = .authorized
        let capturedPhoto = createTestImage()
        viewModel.selectedImage = capturedPhoto
        viewModel.stylePrompt = "portrait style"
        
        let generatedImage = createGeneratedImage()
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.generatedPortrait, "App should work with camera when photo library denied")
    }
    
    func testPermissionHandling_SaveRequiresPhotoLibraryPermission() async {
        // Given - Generate a portrait first
        let selectedPhoto = createTestImage()
        let generatedImage = createGeneratedImage()
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "oil painting"
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        await viewModel.generatePortrait()
        XCTAssertNotNil(viewModel.generatedPortrait, "Portrait should be generated")
        
        // When - Try to save with permission denied
        mockImageService.saveResult = .failure(PermissionError.photoLibraryAccessDenied)
        viewModel.savePortrait()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Then - Verify error is displayed
        XCTAssertNotNil(viewModel.errorMessage, "Error should be displayed when save permission denied")
        XCTAssertTrue(viewModel.errorMessage!.contains("Photo library") || viewModel.errorMessage!.contains("access"),
                      "Error should mention photo library access")
    }
    
    func testPermissionHandling_BothPermissionsGranted() async {
        // Given - Both permissions authorized
        mockPermissionService.cameraPermissionStatus = .authorized
        mockPermissionService.photoLibraryPermissionStatus = .authorized
        
        // Verify both permissions
        XCTAssertEqual(mockPermissionService.checkCameraPermission(), .authorized, "Camera should be authorized")
        XCTAssertEqual(mockPermissionService.checkPhotoLibraryPermission(), .authorized, "Photo library should be authorized")
        
        // Complete full flow
        let capturedPhoto = createTestImage()
        let generatedImage = createGeneratedImage()
        viewModel.selectedImage = capturedPhoto
        viewModel.stylePrompt = "renaissance style"
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        await viewModel.generatePortrait()
        
        mockImageService.saveResult = .success(())
        viewModel.savePortrait()
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertTrue(mockImageService.saveToPhotoLibraryCalled, "Save should succeed with permissions")
    }
}

// MARK: - 14.5 Refresh Workflow
// Test flow: generate portrait → view results → refresh → view new variation
// Requirements: 8.1, 8.2

extension IntegrationTests {
    
    func testRefreshWorkflow_CompleteFlow() async {
        // Given - Generate initial portrait
        let selectedPhoto = createTestImage()
        let initialPortrait = createTestImage(color: .blue, size: CGSize(width: 512, height: 512))
        let refreshedPortrait = createTestImage(color: .purple, size: CGSize(width: 512, height: 512))
        
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "watercolor style"
        mockAPIService.generatePortraitResult = .success(initialPortrait)
        
        // Step 1: Generate initial portrait
        await viewModel.generatePortrait()
        
        XCTAssertNotNil(viewModel.generatedPortrait, "Initial portrait should be generated")
        
        // Step 2: Refresh to get new variation
        // Requirements: 8.1
        mockAPIService.generatePortraitResult = .success(refreshedPortrait)
        mockAPIService.capturedImage = nil
        mockAPIService.capturedStylePrompt = nil
        
        await viewModel.refreshPortrait()
        
        // Verify same inputs were used
        XCTAssertNotNil(mockAPIService.capturedImage, "Same image should be sent on refresh")
        XCTAssertEqual(mockAPIService.capturedStylePrompt, "watercolor style", "Same style prompt should be sent on refresh")
        
        // Step 3: Verify portrait was updated
        // Requirements: 8.2
        XCTAssertNotNil(viewModel.generatedPortrait, "Portrait should exist after refresh")
        XCTAssertFalse(viewModel.isLoading, "Loading should be complete")
    }
    
    func testRefreshWorkflow_UsesSameInputs() async {
        // Given
        let selectedPhoto = createTestImage()
        let stylePrompt = "oil painting masterpiece"
        let initialPortrait = createGeneratedImage()
        let refreshedPortrait = createGeneratedImage()
        
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = stylePrompt
        mockAPIService.generatePortraitResult = .success(initialPortrait)
        
        // Generate initial
        await viewModel.generatePortrait()
        
        // Record the inputs used
        let initialPrompt = mockAPIService.capturedStylePrompt
        
        // Reset captured values
        mockAPIService.capturedImage = nil
        mockAPIService.capturedStylePrompt = nil
        mockAPIService.generatePortraitResult = .success(refreshedPortrait)
        
        // When - Refresh
        await viewModel.refreshPortrait()
        
        // Then - Verify same inputs
        XCTAssertNotNil(mockAPIService.capturedImage, "Image should be sent on refresh")
        XCTAssertEqual(mockAPIService.capturedStylePrompt, initialPrompt, "Same style prompt should be used")
    }
    
    func testRefreshWorkflow_UpdatesDisplayedPortrait() async {
        // Given
        let selectedPhoto = createTestImage()
        let initialPortrait = createTestImage(color: .red, size: CGSize(width: 256, height: 256))
        let refreshedPortrait = createTestImage(color: .green, size: CGSize(width: 256, height: 256))
        
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "cartoon style"
        mockAPIService.generatePortraitResult = .success(initialPortrait)
        
        // Generate initial
        await viewModel.generatePortrait()
        XCTAssertNotNil(viewModel.generatedPortrait, "Initial portrait exists")
        
        // When - Refresh
        mockAPIService.generatePortraitResult = .success(refreshedPortrait)
        await viewModel.refreshPortrait()
        
        // Then - Portrait should be updated (not nil, indicating replacement)
        XCTAssertNotNil(viewModel.generatedPortrait, "Portrait should be updated after refresh")
    }
    
    func testRefreshWorkflow_MultipleRefreshes() async {
        // Given
        let selectedPhoto = createTestImage()
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "abstract art"
        
        // Initial generation
        mockAPIService.generatePortraitResult = .success(createGeneratedImage())
        await viewModel.generatePortrait()
        XCTAssertNotNil(viewModel.generatedPortrait, "Initial portrait generated")
        
        // Multiple refreshes
        for i in 1...3 {
            mockAPIService.generatePortraitResult = .success(createGeneratedImage())
            await viewModel.refreshPortrait()
            
            XCTAssertNotNil(viewModel.generatedPortrait, "Portrait should exist after refresh \(i)")
            XCTAssertFalse(viewModel.isLoading, "Loading should be complete after refresh \(i)")
            XCTAssertNil(viewModel.errorMessage, "No error after refresh \(i)")
        }
    }
    
    func testRefreshWorkflow_LoadingStateDuringRefresh() async {
        // Given
        let selectedPhoto = createTestImage()
        let generatedImage = createGeneratedImage()
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = "portrait style"
        mockAPIService.generatePortraitResult = .success(generatedImage)
        
        // Generate initial
        await viewModel.generatePortrait()
        
        // Track loading state during refresh
        var wasLoadingDuringRefresh = false
        mockAPIService.onGeneratePortrait = { [weak self] in
            wasLoadingDuringRefresh = self?.viewModel.isLoading ?? false
        }
        
        // When - Refresh
        mockAPIService.generatePortraitResult = .success(createGeneratedImage())
        await viewModel.refreshPortrait()
        
        // Then
        XCTAssertTrue(wasLoadingDuringRefresh, "Loading should be true during refresh")
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after refresh")
    }
    
    func testRefreshWorkflow_ErrorPreservesState() async {
        // Given
        let selectedPhoto = createTestImage()
        let stylePrompt = "sketch style"
        let initialPortrait = createGeneratedImage()
        
        viewModel.selectedImage = selectedPhoto
        viewModel.stylePrompt = stylePrompt
        mockAPIService.generatePortraitResult = .success(initialPortrait)
        
        // Generate initial
        await viewModel.generatePortrait()
        XCTAssertNotNil(viewModel.generatedPortrait, "Initial portrait exists")
        
        // When - Refresh fails
        mockAPIService.generatePortraitResult = .failure(APIError.networkError(NSError(domain: "", code: -1)))
        await viewModel.refreshPortrait()
        
        // Then - State should be preserved
        XCTAssertNotNil(viewModel.selectedImage, "Image should be preserved after refresh error")
        XCTAssertEqual(viewModel.stylePrompt, stylePrompt, "Style prompt should be preserved after refresh error")
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be displayed")
    }
}


// MARK: - Mock Classes for Integration Tests

/// Mock API Service for integration testing
class MockAPIServiceForIntegration: APIServiceProtocol {
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

/// Mock Image Service for integration testing
class MockImageServiceForIntegration: ImageServiceProtocol {
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

/// Mock Permission Service for integration testing
class MockPermissionServiceForIntegration: PermissionServiceProtocol {
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
