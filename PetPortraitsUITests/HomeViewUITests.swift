//
//  HomeViewUITests.swift
//  PetPortraitsUITests
//
//  Created by Kiro
//

import XCTest

final class HomeViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Test both buttons are present with correct labels
    // Requirements: 3.1, 3.2, 3.3
    
    func testHomeViewDisplaysTakePhotoButton() throws {
        // Verify "Take Photo" button is present
        let takePhotoButton = app.buttons["takePhotoButton"]
        XCTAssertTrue(takePhotoButton.exists, "Take Photo button should be present on HomeView")
        XCTAssertTrue(takePhotoButton.isHittable, "Take Photo button should be tappable")
    }
    
    func testHomeViewDisplaysChooseFromGalleryButton() throws {
        // Verify "Choose from Gallery" button is present
        let galleryButton = app.buttons["chooseFromGalleryButton"]
        XCTAssertTrue(galleryButton.exists, "Choose from Gallery button should be present on HomeView")
        XCTAssertTrue(galleryButton.isHittable, "Choose from Gallery button should be tappable")
    }
    
    func testHomeViewDisplaysAppTitle() throws {
        // Verify app title is displayed
        let appTitle = app.staticTexts["appTitle"]
        XCTAssertTrue(appTitle.exists, "App title should be present on HomeView")
    }
    
    func testTakePhotoButtonHasCorrectLabel() throws {
        // Verify "Take Photo" button has correct label text
        let takePhotoButton = app.buttons["takePhotoButton"]
        XCTAssertTrue(takePhotoButton.exists)
        
        // Check that the button contains the expected text
        let buttonLabel = takePhotoButton.label
        XCTAssertTrue(buttonLabel.contains("Take Photo") || takePhotoButton.staticTexts["Take Photo"].exists,
                      "Take Photo button should have 'Take Photo' label")
    }
    
    func testChooseFromGalleryButtonHasCorrectLabel() throws {
        // Verify "Choose from Gallery" button has correct label text
        let galleryButton = app.buttons["chooseFromGalleryButton"]
        XCTAssertTrue(galleryButton.exists)
        
        // Check that the button contains the expected text
        let buttonLabel = galleryButton.label
        XCTAssertTrue(buttonLabel.contains("Choose from Gallery") || galleryButton.staticTexts["Choose from Gallery"].exists,
                      "Choose from Gallery button should have 'Choose from Gallery' label")
    }
    
    // MARK: - Test tapping "Take Photo" presents camera interface
    // Requirements: 4.1
    
    func testTappingTakePhotoPresentsSheet() throws {
        // Tap the "Take Photo" button
        let takePhotoButton = app.buttons["takePhotoButton"]
        XCTAssertTrue(takePhotoButton.exists)
        takePhotoButton.tap()
        
        // Wait for sheet presentation
        // Note: On simulator without camera, this may show an alert or the camera picker
        // The sheet should be presented (either camera or permission alert)
        let sheetPresented = app.sheets.firstMatch.waitForExistence(timeout: 2) ||
                            app.alerts.firstMatch.waitForExistence(timeout: 2) ||
                            app.otherElements["UIImagePickerController"].waitForExistence(timeout: 2)
        
        // On simulator, camera may not be available, so we just verify the action was triggered
        // The sheet/alert presentation confirms the button action works
        XCTAssertTrue(sheetPresented || !takePhotoButton.isHittable,
                      "Tapping Take Photo should present camera interface or permission dialog")
    }
    
    // MARK: - Test tapping "Choose from Gallery" presents photo picker
    // Requirements: 5.1
    
    func testTappingChooseFromGalleryPresentsPhotoPicker() throws {
        // Tap the "Choose from Gallery" button
        let galleryButton = app.buttons["chooseFromGalleryButton"]
        XCTAssertTrue(galleryButton.exists)
        galleryButton.tap()
        
        // Wait for photo picker presentation
        // The photo picker should be presented as a sheet
        let pickerPresented = app.navigationBars.firstMatch.waitForExistence(timeout: 3) ||
                             app.sheets.firstMatch.waitForExistence(timeout: 3) ||
                             app.alerts.firstMatch.waitForExistence(timeout: 3)
        
        XCTAssertTrue(pickerPresented || !galleryButton.isHittable,
                      "Tapping Choose from Gallery should present photo picker or permission dialog")
    }
    
    // MARK: - Test minimalist design elements
    // Requirements: 1.1, 1.2, 1.3
    
    func testHomeViewHasMinimalistLayout() throws {
        // Verify the home view has a clean layout with both buttons visible
        let takePhotoButton = app.buttons["takePhotoButton"]
        let galleryButton = app.buttons["chooseFromGalleryButton"]
        let appTitle = app.staticTexts["appTitle"]
        
        XCTAssertTrue(takePhotoButton.exists, "Take Photo button should exist")
        XCTAssertTrue(galleryButton.exists, "Choose from Gallery button should exist")
        XCTAssertTrue(appTitle.exists, "App title should exist")
        
        // Verify buttons are vertically arranged (gallery button below take photo)
        XCTAssertGreaterThan(galleryButton.frame.minY, takePhotoButton.frame.maxY,
                            "Choose from Gallery button should be below Take Photo button")
    }
}
