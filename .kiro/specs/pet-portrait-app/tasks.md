# Implementation Plan: Pet Portrait App

## Overview

This implementation plan breaks down the Pet Portrait App into discrete coding tasks following the MVVM architecture pattern. The app will be built using SwiftUI for the UI layer, with UIKit bridges for camera and photo picker access, and integration with the Google Nano Banana Pro API for AI image generation.

The implementation follows an incremental approach: starting with project setup and core infrastructure, then building out the service layer, followed by the ViewModel and View components, and finally adding comprehensive testing including property-based tests for all 14 correctness properties.

## Tasks

- [x] 1. Set up project structure and configuration
  - [x] 1.1 Create Xcode project with SwiftUI lifecycle
    - Create new iOS App project in Xcode
    - Configure Info.plist with camera and photo library usage descriptions
    - Add SwiftCheck dependency for property-based testing
    - Set up project folder structure (Views, ViewModels, Services, Models, UIKitBridges)
    - Configure minimum iOS deployment target (iOS 15.0)
    - _Requirements: 1.1, 11.2, 12.2_
    
    ⚠️ **USER ACTION REQUIRED**: You must open Xcode to:
    1. Create the new iOS App project (File → New → Project)
    2. Configure project settings and bundle identifier
    3. Add SwiftCheck via Swift Package Manager (File → Add Package Dependencies)
       - Package URL: https://github.com/typelift/SwiftCheck
  
  - [x] 1.2 Initialize Git repository and push to GitHub
    - Run `git init` in PetPortraits directory
    - Create .gitignore file for Xcode projects (exclude build artifacts, .DS_Store, etc.)
    - Run `git add .` to stage all files
    - Run `git commit -m "Initial project setup with Xcode configuration"`
    - Create GitHub repository (if not already created)
    - Run `git remote add origin <your-github-repo-url>`
    - Run `git push -u origin main`
    
    ⚠️ **USER ACTION REQUIRED**: Before pushing to GitHub, you must:
    1. Log into GitHub (github.com) in your browser
    2. Create a new repository for this project
    3. Copy the repository URL to use with `git remote add origin`
    4. Ensure you have GitHub authentication configured (SSH key or personal access token)

- [x] 2. Implement data models and error types
  - [x] 2.1 Create Portrait model with Identifiable and Codable conformance
    - Define Portrait struct with id, originalImageData, generatedImageData, stylePrompt, and createdAt properties
    - _Requirements: 2.1, 2.2, 6.1_
  
  - [x] 2.2 Create APIError enum with LocalizedError conformance
    - Define error cases: networkError, invalidResponse, apiError, imageConversionError
    - Implement user-friendly error descriptions for each case
    - _Requirements: 13.1, 13.3_
  
  - [x] 2.3 Create PermissionError enum with LocalizedError conformance
    - Define error cases: cameraAccessDenied, photoLibraryAccessDenied
    - Implement user-friendly error descriptions with Settings guidance
    - _Requirements: 11.1, 12.1_
  
  - [x] 2.4 Create APIRequest and APIResponse structs
    - Define APIRequest with image, stylePrompt, and apiKey properties
    - Define APIResponse with imageData property
    - _Requirements: 2.1, 2.2, 2.3_

- [x] 3. Implement PermissionService
  - [x] 3.1 Create PermissionService protocol and implementation
    - Define PermissionStatus enum (notDetermined, authorized, denied)
    - Implement checkCameraPermission() method using AVCaptureDevice
    - Implement requestCameraPermission() async method
    - Implement checkPhotoLibraryPermission() method using PHPhotoLibrary
    - Implement requestPhotoLibraryPermission() async method
    - _Requirements: 11.1, 11.2, 12.1, 12.2_
  
  - [x] 3.2 Write unit tests for PermissionService
    - Test permission status checks for all states
    - Test permission request flows
    - Test edge cases (denied, restricted states)
    - _Requirements: 11.1, 12.1_

- [x] 4. Implement ImageService
  - [x] 4.1 Create ImageService protocol and implementation
    - Implement saveToPhotoLibrary(_ image: UIImage) async throws method
    - Use PHPhotoLibrary.shared().performChanges for saving
    - Handle photo library write permission errors
    - _Requirements: 9.2_
  
  - [x] 4.2 Write unit tests for ImageService
    - Test successful save operation with mocked PHPhotoLibrary
    - Test permission denied error handling
    - Test save failure scenarios
    - _Requirements: 9.2_

- [x] 5. Implement APIService
  - [x] 5.1 Create APIService protocol and implementation
    - Define baseURL and apiKey properties
    - Implement generatePortrait(image: UIImage, stylePrompt: String) async throws method
    - Create multipart form data request with image and style prompt
    - Parse API response and convert to UIImage
    - Handle network errors, invalid responses, and API errors
    - _Requirements: 2.1, 2.2, 2.3, 6.1_
  
  - [x] 5.2 Write unit tests for APIService
    - Test successful API request and response parsing
    - Test network error handling
    - Test invalid response handling
    - Test API error response parsing
    - Test image conversion errors
    - Use URLProtocol mocking for network requests
    - _Requirements: 2.1, 2.2, 2.3, 13.1, 13.3_

- [x] 6. Checkpoint - Service layer complete
  - [x] 6.1 Ensure all service tests pass
    - Run all unit tests for PermissionService, ImageService, and APIService
    - Verify no compiler warnings or errors
    - Ask the user if questions arise
    
    ⚠️ **USER ACTION REQUIRED**: You must run tests in Xcode:
    1. Open the project in Xcode
    2. Press ⌘+U to run all tests
    3. Verify all tests pass in the Test Navigator (⌘+6)
  
  - [x] 6.2 Commit and push service layer to GitHub
    - Run `git add .` to stage all service layer files
    - Run `git commit -m "Implement service layer: PermissionService, ImageService, APIService with tests"`
    - Run `git push origin main`

- [x] 7. Implement PortraitViewModel
  - [x] 7.1 Create PortraitViewModel class with ObservableObject conformance
    - Define @Published properties: selectedImage, stylePrompt, generatedPortrait, isLoading, errorMessage
    - Inject APIService, ImageService, and PermissionService dependencies
    - Initialize with empty/default state
    - _Requirements: 4.2, 5.2, 6.2, 7.1, 7.2, 13.2, 13.4_
  
  - [x] 7.2 Implement generatePortrait() async method
    - Set isLoading to true and disable generate button
    - Call APIService.generatePortrait with selectedImage and stylePrompt
    - Update generatedPortrait with API response
    - Handle errors by setting errorMessage and preserving input state
    - Set isLoading to false when complete
    - _Requirements: 6.1, 6.2, 7.1, 7.2, 13.1, 13.2, 13.3, 13.4, 13.5_
  
  - [x] 7.3 Implement refreshPortrait() async method
    - Reuse the same selectedImage and stylePrompt (no modification)
    - Call generatePortrait() logic to fetch new variation
    - Update generatedPortrait with new result
    - _Requirements: 8.1, 8.2_
  
  - [x] 7.4 Implement savePortrait() method
    - Call ImageService.saveToPhotoLibrary with generatedPortrait
    - Handle errors and display appropriate error messages
    - _Requirements: 9.1, 9.2_
  
  - [x] 7.5 Implement sharePortrait() method
    - Return array containing generatedPortrait for share sheet
    - _Requirements: 10.1, 10.2_
  
  - [x] 7.6 Write unit tests for PortraitViewModel
    - Test initial state (empty image, empty prompt, not loading)
    - Test generatePortrait success flow with mocked APIService
    - Test generatePortrait error handling and state preservation
    - Test refreshPortrait uses same inputs
    - Test savePortrait calls ImageService correctly
    - Test sharePortrait returns correct data
    - Test loading state transitions
    - _Requirements: 6.1, 6.2, 7.1, 7.2, 8.1, 8.2, 9.2, 10.1, 13.2, 13.4, 13.5_

- [ ] 8. Implement UIKit bridge components
  - [ ] 8.1 Create CameraViewController with UIViewControllerRepresentable
    - Implement makeUIViewController to create UIImagePickerController with camera source
    - Implement Coordinator to handle UIImagePickerControllerDelegate callbacks
    - Bind captured image to @Binding var image
    - Dismiss presentation on image capture or cancel
    - _Requirements: 4.1, 4.2_
  
  - [ ] 8.2 Create PhotoPickerViewController with UIViewControllerRepresentable
    - Implement makeUIViewController to create UIImagePickerController with photo library source
    - Implement Coordinator to handle UIImagePickerControllerDelegate callbacks
    - Bind selected image to @Binding var image
    - Dismiss presentation on image selection or cancel
    - _Requirements: 5.1, 5.2_
  
  - [ ]* 8.3 Write unit tests for UIKit bridges
    - Test CameraViewController creates correct UIImagePickerController configuration
    - Test PhotoPickerViewController creates correct UIImagePickerController configuration
    - Test Coordinator delegate methods update bindings correctly
    - _Requirements: 4.1, 4.2, 5.1, 5.2_

- [ ] 9. Implement HomeView
  - [ ] 9.1 Create HomeView with minimalist design
    - Display app title with ample white space
    - Create "Take Photo" button that sets showCamera to true
    - Create "Choose from Gallery" button that sets showPhotoPicker to true
    - Use native SwiftUI components (Button, VStack, Spacer)
    - Apply minimalist styling with white space
    - _Requirements: 1.1, 1.2, 1.3, 3.1, 3.2, 3.3_
  
  - [ ] 9.2 Add camera and photo picker presentation logic
    - Present CameraViewController when showCamera is true
    - Present PhotoPickerViewController when showPhotoPicker is true
    - Bind selectedImage from ViewModel to both pickers
    - Navigate to CaptureView when image is selected
    - _Requirements: 4.1, 5.1_
  
  ⚠️ **USER ACTION REQUIRED**: Before writing UI tests, re-enable the UI test target:
    1. Go to **Product → Scheme → Edit Scheme**
    2. Select "Test" on the left sidebar
    3. Check the box next to `PetPortraitsUITests`
    4. Click "Close"
  
  - [ ]* 9.3 Write UI tests for HomeView
    - Test both buttons are present with correct labels
    - Test tapping "Take Photo" presents camera interface
    - Test tapping "Choose from Gallery" presents photo picker
    - Test navigation to CaptureView after image selection
    - _Requirements: 3.1, 3.2, 3.3, 4.1, 5.1_

- [ ] 10. Implement CaptureView
  - [ ] 10.1 Create CaptureView with image display and style input
    - Display selectedImage from ViewModel using Image view
    - Create TextField labeled "How should we style your pet?" bound to stylePrompt
    - Create "Generate" button that calls viewModel.generatePortrait()
    - Disable "Generate" button when isLoading is true
    - Display loading animation when isLoading is true (ProgressView)
    - Use native SwiftUI components with minimalist design
    - _Requirements: 1.1, 1.2, 1.3, 4.2, 4.3, 5.2, 5.3, 6.1, 7.1, 7.2, 7.3_
  
  - [ ] 10.2 Add error handling UI
    - Display alert when errorMessage is not nil
    - Show localized error message in alert
    - Provide "Retry" button in alert that dismisses and keeps inputs preserved
    - Ensure "Generate" button is enabled after error for retry
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_
  
  - [ ] 10.3 Add navigation to ResultsView
    - Navigate to ResultsView when generatedPortrait is not nil
    - Pass ViewModel to ResultsView
    - _Requirements: 6.2_
  
  - [ ]* 10.4 Write UI tests for CaptureView
    - Test image displays correctly
    - Test style input field is present with correct label
    - Test "Generate" button is enabled when not loading
    - Test "Generate" button is disabled during loading
    - Test loading animation appears during API call
    - Test error alert displays with correct message
    - Test navigation to ResultsView on success
    - _Requirements: 4.2, 4.3, 5.2, 5.3, 6.1, 7.1, 7.2, 13.1, 13.5_

- [ ] 11. Implement ResultsView
  - [ ] 11.1 Create ResultsView with portrait display and action buttons
    - Display generatedPortrait from ViewModel using Image view
    - Create "Refresh" button that calls viewModel.refreshPortrait()
    - Create "Save" button that calls viewModel.savePortrait()
    - Create "Share" button that presents share sheet
    - Disable buttons when isLoading is true during refresh
    - Display loading animation when isLoading is true
    - Use native SwiftUI components with minimalist design
    - _Requirements: 1.1, 1.2, 1.3, 6.2, 6.3, 8.1, 9.1_
  
  - [ ] 11.2 Implement share sheet presentation
    - Use sheet modifier to present ActivityViewController
    - Populate share sheet with items from viewModel.sharePortrait()
    - Use UIViewControllerRepresentable wrapper for UIActivityViewController
    - _Requirements: 10.1, 10.2, 10.3_
  
  - [ ] 11.3 Add error handling for save and refresh operations
    - Display alert when errorMessage is not nil
    - Show localized error message in alert
    - Preserve state for retry on refresh errors
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_
  
  - [ ]* 11.4 Write UI tests for ResultsView
    - Test generated portrait displays correctly
    - Test all three action buttons are present with correct labels
    - Test "Refresh" button triggers refresh operation
    - Test "Save" button triggers save operation
    - Test "Share" button presents share sheet
    - Test loading state during refresh operation
    - Test error handling for failed operations
    - _Requirements: 6.2, 6.3, 8.1, 8.2, 9.1, 10.1, 13.1, 13.5_

- [ ] 12. Checkpoint - UI layer complete
  - [ ] 12.1 Ensure all UI tests pass
    - Run all unit tests for PortraitViewModel and UIKit bridges
    - Run all UI tests for HomeView, CaptureView, and ResultsView
    - Verify app runs successfully on simulator
    - Test complete user flow manually
    - Ask the user if questions arise
    
    ⚠️ **USER ACTION REQUIRED**: You must test in Xcode:
    1. Run all tests with ⌘+U
    2. Run the app on simulator (⌘+R) and manually test the UI flow
    3. Test on a physical device if available (requires Apple Developer account)
  
  - [ ] 12.2 Commit and push UI layer to GitHub
    - Run `git add .` to stage all UI layer files
    - Run `git commit -m "Implement UI layer: PortraitViewModel, all Views, and UIKit bridges with tests"`
    - Run `git push origin main`

- [ ] 13. Implement property-based tests for correctness properties
  - [ ]* 13.1 Set up SwiftCheck configuration and custom generators
    - Configure CheckerArguments with 100 minimum iterations
    - Create UIImage generator for random test images
    - Create String generator for style prompts with various lengths
    - Create APIResponse generator for valid and invalid responses
    - Create PermissionStatus generator for all permission states
    - Create APIError generator for various error types
    - _Requirements: All requirements (testing infrastructure)_
  
  - [ ]* 13.2 Write property test for Property 1: API Request Completeness
    - **Property 1: API Request Completeness**
    - **Validates: Requirements 2.2, 6.1**
    - Generate random images and style prompts
    - Verify API requests include both image data and style prompt text
    - Use forAll with image and prompt generators
  
  - [ ]* 13.3 Write property test for Property 2: API Response Display
    - **Property 2: API Response Display**
    - **Validates: Requirements 2.3, 6.2**
    - Generate random successful API responses
    - Verify generatedPortrait updates with received image
    - Test across various image formats and sizes
  
  - [ ]* 13.4 Write property test for Property 3: Image Selection Display
    - **Property 3: Image Selection Display**
    - **Validates: Requirements 4.2, 5.2**
    - Generate random images for selection
    - Verify selectedImage displays in CaptureView
    - Test for both camera and photo picker sources
  
  - [ ]* 13.5 Write property test for Property 4: Style Input Availability
    - **Property 4: Style Input Availability**
    - **Validates: Requirements 4.3, 5.3**
    - Generate random image selection events
    - Verify style input field appears with correct label
    - Test for both camera and photo picker sources
  
  - [ ]* 13.6 Write property test for Property 5: Camera Interface Activation
    - **Property 5: Camera Interface Activation**
    - **Validates: Requirements 4.1**
    - Generate random initial app states
    - Verify camera interface presents when "Take Photo" tapped
    - Test across various ViewModel states
  
  - [ ]* 13.7 Write property test for Property 6: Photo Picker Activation
    - **Property 6: Photo Picker Activation**
    - **Validates: Requirements 5.1**
    - Generate random initial app states
    - Verify photo picker presents when "Choose from Gallery" tapped
    - Test across various ViewModel states
  
  - [ ]* 13.8 Write property test for Property 7: Loading State Behavior
    - **Property 7: Loading State Behavior**
    - **Validates: Requirements 7.1, 7.2**
    - Generate random API request scenarios
    - Verify "Generate" button is disabled during loading
    - Verify loading animation is displayed during loading
    - Test for both generate and refresh operations
  
  - [ ]* 13.9 Write property test for Property 8: Refresh Input Preservation
    - **Property 8: Refresh Input Preservation**
    - **Validates: Requirements 8.1**
    - Generate random images and style prompts
    - Trigger refresh operation
    - Verify identical image and style prompt sent to API (no modifications)
  
  - [ ]* 13.10 Write property test for Property 9: Refresh Portrait Update
    - **Property 9: Refresh Portrait Update**
    - **Validates: Requirements 8.2**
    - Generate random refresh API responses
    - Verify displayed portrait updates to new image
    - Test that old portrait is replaced, not appended
  
  - [ ]* 13.11 Write property test for Property 10: Portrait Persistence
    - **Property 10: Portrait Persistence**
    - **Validates: Requirements 9.2**
    - Generate random generated portraits
    - Trigger save operation
    - Verify ImageService.saveToPhotoLibrary called with correct image
  
  - [ ]* 13.12 Write property test for Property 11: Share Sheet Presentation
    - **Property 11: Share Sheet Presentation**
    - **Validates: Requirements 10.1, 10.2**
    - Generate random generated portraits
    - Trigger share operation
    - Verify share sheet presents with generated portrait image
  
  - [ ]* 13.13 Write property test for Property 12: Error Message Display
    - **Property 12: Error Message Display**
    - **Validates: Requirements 13.1, 13.3**
    - Generate random error conditions (API errors, network failures)
    - Verify localized error message displays for each error type
    - Test all error cases from APIError enum
  
  - [ ]* 13.14 Write property test for Property 13: Error State Preservation
    - **Property 13: Error State Preservation (Invariant)**
    - **Validates: Requirements 13.2, 13.4**
    - Generate random errors and user inputs (image, style prompt)
    - Trigger error condition
    - Verify selectedImage and stylePrompt remain unchanged
    - Test across all error types
  
  - [ ]* 13.15 Write property test for Property 14: Error Recovery Capability
    - **Property 14: Error Recovery Capability**
    - **Validates: Requirements 13.5**
    - Generate random error states
    - Verify "Generate" button is enabled after error
    - Verify user can retry with preserved inputs

- [ ] 14. Implement integration tests for end-to-end workflows
  - [ ]* 14.1 Write integration test for happy path: photo selection to save
    - Test complete flow: launch → select photo → enter prompt → generate → view results → save
    - Verify all state transitions and UI updates
    - Use mocked APIService for predictable results
    - _Requirements: 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 9.1, 9.2_
  
  - [ ]* 14.2 Write integration test for happy path: camera capture to share
    - Test complete flow: launch → take photo → enter prompt → generate → view results → share
    - Verify all state transitions and UI updates
    - Use mocked camera and APIService
    - _Requirements: 4.1, 4.2, 4.3, 6.1, 6.2, 6.3, 10.1, 10.2, 10.3_
  
  - [ ]* 14.3 Write integration test for error recovery path
    - Test flow: select photo → enter prompt → generate (network error) → retry → success
    - Verify error message display and state preservation
    - Verify successful retry with preserved inputs
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_
  
  - [ ]* 14.4 Write integration test for permission handling
    - Test flow: launch → take photo (no permission) → grant permission → take photo → success
    - Verify permission request and handling
    - Test both camera and photo library permissions
    - _Requirements: 11.1, 11.2, 12.1, 12.2_
  
  - [ ]* 14.5 Write integration test for refresh workflow
    - Test flow: generate portrait → view results → refresh → view new variation
    - Verify same inputs used for refresh
    - Verify portrait updates correctly
    - _Requirements: 8.1, 8.2_

- [ ] 15. Wire all components together in App entry point
  - [ ] 15.1 Create PetPortraitApp struct with @main attribute
    - Set up SwiftUI App lifecycle
    - Initialize PortraitViewModel with service dependencies
    - Create APIService with API key from configuration
    - Create ImageService and PermissionService instances
    - Set HomeView as root view with ViewModel injected
    - _Requirements: All requirements (application entry point)_
  
  - [ ] 15.2 Configure app-level settings
    - Set up Info.plist usage descriptions for camera and photo library
    - Configure API key storage (use environment variable or config file)
    - Set app display name and bundle identifier
    - _Requirements: 11.2, 12.2_
    
    ⚠️ **USER ACTION REQUIRED**: Before this task can be completed, you must:
    1. Choose an AI image generation API service (e.g., OpenAI DALL-E, Stability AI, Replicate)
    2. Create an account and obtain your API key from the chosen service
    3. Update the `baseURL` in `APIService.swift` to match your chosen API's endpoint
    4. Provide your API key - Kiro will help you configure secure storage
    
    _Note: The current implementation uses a placeholder "Nano Banana Pro" API. The actual API endpoint and request format may need adjustment based on your chosen service._

- [ ] 16. Final checkpoint - Complete implementation
  - [ ] 16.1 Run comprehensive test suite
    - Run all unit tests, property-based tests, integration tests, and UI tests
    - Verify all 14 correctness properties pass with 100+ iterations
    - Ensure no compiler warnings or errors
    - Verify app runs successfully on simulator
    - Test all user workflows end-to-end
    - Ask the user if questions arise
    
    ⚠️ **USER ACTION REQUIRED**: Final verification in Xcode:
    1. Run full test suite with ⌘+U
    2. Run app on simulator and physical device
    3. Test complete user flow: photo capture → style input → generate → save/share
    4. Verify API integration works with your configured API key
  
  - [ ] 16.2 Final commit and push to GitHub
    - Run `git add .` to stage all remaining files
    - Run `git commit -m "Complete Pet Portrait App implementation with comprehensive test suite"`
    - Run `git push origin main`
    - Create GitHub release tag: `git tag -a v1.0.0 -m "Initial release"`
    - Run `git push origin v1.0.0`
    
    ⚠️ **USER ACTION REQUIRED (Optional)**: For App Store distribution:
    1. Enroll in Apple Developer Program ($99/year) at developer.apple.com
    2. Create App Store Connect record for your app
    3. Configure signing certificates and provisioning profiles in Xcode
    4. Archive and upload build via Xcode (Product → Archive)

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property-based tests validate all 14 correctness properties from the design document
- The implementation follows MVVM architecture with clear separation of concerns
- All services use protocol-based design for testability and dependency injection
- SwiftCheck is used for property-based testing with minimum 100 iterations per property
- Integration tests verify complete user workflows end-to-end
- Checkpoints ensure incremental validation at key milestones

## Git/GitHub Workflow

The implementation includes Git commits at three key checkpoints:

1. **After Task 1**: Initial project setup and configuration
2. **After Task 6**: Service layer complete (PermissionService, ImageService, APIService)
3. **After Task 12**: UI layer complete (ViewModel, Views, UIKit bridges)
4. **After Task 16**: Final implementation with all tests passing

Each checkpoint includes:
- Running tests to ensure quality
- Staging all changes with `git add .`
- Creating a descriptive commit message
- Pushing to GitHub with `git push origin main`

The final checkpoint also creates a release tag (v1.0.0) for the initial version.
