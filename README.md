# Pet Portrait App

An iOS application that transforms pet photos into AI-generated stylized portraits using the Google Nano Banana Pro API.

## Project Setup

### Creating the Xcode Project

Since Xcode project files cannot be created programmatically, follow these steps to set up the Xcode project:

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose "iOS" → "App" template
4. Configure the project:
   - Product Name: `PetPortraits`
   - Interface: `SwiftUI`
   - Life Cycle: `SwiftUI App`
   - Language: `Swift`
   - Minimum Deployment: `iOS 15.0`
5. Save the project in the `PetPortraits` directory

### Adding SwiftCheck Dependency

1. In Xcode, select your project in the navigator
2. Select the project target
3. Go to "Package Dependencies" tab
4. Click the "+" button
5. Enter the repository URL: `https://github.com/typelift/SwiftCheck.git`
6. Select version: `0.12.0` or later
7. Add to target: `PetPortraitsTests`

### Copying Source Files

The source files have been created in the following structure:

```
PetPortraits/
├── PetPortraits/
│   ├── PetPortraitsApp.swift
│   ├── Info.plist
│   ├── Views/
│   │   ├── HomeView.swift
│   │   ├── CaptureView.swift
│   │   └── ResultsView.swift
│   ├── ViewModels/
│   │   └── PortraitViewModel.swift
│   ├── Services/
│   │   ├── APIService.swift
│   │   ├── ImageService.swift
│   │   └── PermissionService.swift
│   ├── Models/
│   │   ├── Portrait.swift
│   │   └── APIError.swift
│   └── UIKitBridges/
│       ├── CameraViewController.swift
│       └── PhotoPickerViewController.swift
```

After creating the Xcode project, ensure all these files are added to the project target.

### Configuration

The `Info.plist` file includes the required usage descriptions for:
- Camera access (`NSCameraUsageDescription`)
- Photo library read access (`NSPhotoLibraryUsageDescription`)
- Photo library write access (`NSPhotoLibraryAddUsageDescription`)

### API Configuration

Before running the app, you'll need to configure the Google Nano Banana Pro API:

1. Obtain an API key from Google
2. Update the `APIService.swift` file with your API key
3. Verify the API endpoint URL is correct

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Views**: SwiftUI views for UI presentation
- **ViewModels**: State management and business logic
- **Services**: API communication, image handling, and permissions
- **Models**: Data structures and error types
- **UIKitBridges**: SwiftUI wrappers for UIKit components (camera, photo picker)

## Requirements

- iOS 15.0 or later
- Xcode 14.0 or later
- Swift 5.9 or later
- SwiftCheck 0.12.0 or later (for property-based testing)

## Testing

The project uses a dual testing approach:
- Unit tests with XCTest
- Property-based tests with SwiftCheck

See the design document for detailed testing strategy.
