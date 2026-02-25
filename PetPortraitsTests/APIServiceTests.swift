//
//  APIServiceTests.swift
//  PetPortraitsTests
//
//  Created by Kiro
//

import XCTest
import UIKit
@testable import PetPortraits

/// Tests for APIService - validates Requirements 2.1, 2.2, 2.3, 13.1, 13.3
/// THE Pet_Portrait_App SHALL integrate with the Nano_Banana_Pro_API for all image generation requests
/// THE Pet_Portrait_App SHALL send both the original pet image and Style_Prompt to the Nano_Banana_Pro_API
/// THE Pet_Portrait_App SHALL receive and display AI-generated portraits returned by the Nano_Banana_Pro_API
/// IF the Nano_Banana_Pro_API returns an error response, THEN THE Pet_Portrait_App SHALL display a localized error message
/// IF a network failure occurs during API communication, THEN THE Pet_Portrait_App SHALL display a localized error message
class APIServiceTests: XCTestCase {
    
    var sut: APIService!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        
        // Configure URLSession with MockURLProtocol
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
        
        sut = APIService(
            baseURL: URL(string: "https://api.test.com")!,
            apiKey: "test-api-key",
            session: mockSession
        )
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        MockURLProtocol.capturedBodyData = nil
        sut = nil
        mockSession = nil
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
    
    private func createValidImageData() -> Data {
        let image = createTestImage()
        return image.pngData()!
    }
    
    // MARK: - Successful API Request Tests (Requirements 2.1, 2.2, 2.3)
    
    func testGeneratePortrait_WhenSuccessful_ReturnsImage() async throws {
        // Given
        let testImage = createTestImage()
        let responseImageData = createValidImageData()
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseImageData)
        }
        
        // When
        let result = try await sut.generatePortrait(image: testImage, stylePrompt: "watercolor style")
        
        // Then
        XCTAssertNotNil(result, "Should return a valid image")
    }
    
    func testGeneratePortrait_WhenSuccessful_SendsCorrectEndpoint() async throws {
        // Given
        let testImage = createTestImage()
        let responseImageData = createValidImageData()
        var capturedRequest: URLRequest?
        
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseImageData)
        }
        
        // When
        _ = try await sut.generatePortrait(image: testImage, stylePrompt: "oil painting")
        
        // Then
        XCTAssertEqual(capturedRequest?.url?.path, "/v1/generate", "Should send to correct endpoint")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST", "Should use POST method")
    }
    
    func testGeneratePortrait_WhenSuccessful_SendsAuthorizationHeader() async throws {
        // Given
        let testImage = createTestImage()
        let responseImageData = createValidImageData()
        var capturedRequest: URLRequest?
        
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseImageData)
        }
        
        // When
        _ = try await sut.generatePortrait(image: testImage, stylePrompt: "sketch")
        
        // Then
        let authHeader = capturedRequest?.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(authHeader, "Bearer test-api-key", "Should include correct authorization header")
    }
    
    func testGeneratePortrait_WhenSuccessful_SendsMultipartFormData() async throws {
        // Given
        let testImage = createTestImage()
        let responseImageData = createValidImageData()
        var capturedRequest: URLRequest?
        
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseImageData)
        }
        
        // When
        _ = try await sut.generatePortrait(image: testImage, stylePrompt: "cartoon")
        
        // Then
        let contentType = capturedRequest?.value(forHTTPHeaderField: "Content-Type")
        XCTAssertTrue(contentType?.contains("multipart/form-data") ?? false, "Should use multipart/form-data content type")
        XCTAssertTrue(contentType?.contains("boundary=") ?? false, "Should include boundary in content type")
    }
    
    func testGeneratePortrait_WhenSuccessful_IncludesImageInBody() async throws {
        // Given
        let testImage = createTestImage()
        let responseImageData = createValidImageData()
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseImageData)
        }
        
        // When
        _ = try await sut.generatePortrait(image: testImage, stylePrompt: "portrait")
        
        // Then
        let bodyData = MockURLProtocol.capturedBodyData ?? Data()
        // Check for multipart form-data markers in the raw data
        let imageFieldMarker = "name=\"image\"".data(using: .utf8)!
        let filenameMarker = "filename=\"pet.jpg\"".data(using: .utf8)!
        let contentTypeMarker = "Content-Type: image/jpeg".data(using: .utf8)!
        
        XCTAssertTrue(bodyData.range(of: imageFieldMarker) != nil, "Should include image field in body")
        XCTAssertTrue(bodyData.range(of: filenameMarker) != nil, "Should include filename")
        XCTAssertTrue(bodyData.range(of: contentTypeMarker) != nil, "Should specify image content type")
    }
    
    func testGeneratePortrait_WhenSuccessful_IncludesPromptInBody() async throws {
        // Given
        let testImage = createTestImage()
        let stylePrompt = "watercolor painting of a cute dog"
        let responseImageData = createValidImageData()
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseImageData)
        }
        
        // When
        _ = try await sut.generatePortrait(image: testImage, stylePrompt: stylePrompt)
        
        // Then
        let bodyData = MockURLProtocol.capturedBodyData ?? Data()
        let promptFieldMarker = "name=\"prompt\"".data(using: .utf8)!
        let promptValueMarker = stylePrompt.data(using: .utf8)!
        
        XCTAssertTrue(bodyData.range(of: promptFieldMarker) != nil, "Should include prompt field in body")
        XCTAssertTrue(bodyData.range(of: promptValueMarker) != nil, "Should include the actual style prompt text")
    }

    
    // MARK: - Network Error Handling Tests (Requirement 13.3)
    
    func testGeneratePortrait_WhenNetworkError_ThrowsNetworkError() async {
        // Given
        let testImage = createTestImage()
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        
        MockURLProtocol.requestHandler = { _ in
            throw networkError
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.networkError")
        } catch let error as APIError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Should throw networkError, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_WhenConnectionTimeout_ThrowsNetworkError() async {
        // Given
        let testImage = createTestImage()
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        
        MockURLProtocol.requestHandler = { _ in
            throw timeoutError
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.networkError")
        } catch let error as APIError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Should throw networkError for timeout, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_WhenDNSLookupFails_ThrowsNetworkError() async {
        // Given
        let testImage = createTestImage()
        let dnsError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost, userInfo: nil)
        
        MockURLProtocol.requestHandler = { _ in
            throw dnsError
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.networkError")
        } catch let error as APIError {
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Should throw networkError for DNS failure, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_NetworkError_HasUserFriendlyDescription() async {
        // Given
        let testImage = createTestImage()
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        
        MockURLProtocol.requestHandler = { _ in
            throw networkError
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw error")
        } catch let error as APIError {
            let description = error.errorDescription
            XCTAssertNotNil(description, "Error should have a description")
            XCTAssertTrue(description!.contains("internet") || description!.contains("connect"), "Description should mention connectivity")
        } catch {
            XCTFail("Should throw APIError")
        }
    }
    
    // MARK: - Invalid Response Handling Tests
    
    func testGeneratePortrait_WhenNonHTTPResponse_ThrowsInvalidResponse() async {
        // Given
        let testImage = createTestImage()
        
        MockURLProtocol.requestHandler = { request in
            // Return a non-HTTP URLResponse
            let response = URLResponse(
                url: request.url!,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (response, Data())
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.invalidResponse")
        } catch let error as APIError {
            if case .invalidResponse = error {
                // Expected
            } else {
                XCTFail("Should throw invalidResponse, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_InvalidResponse_HasUserFriendlyDescription() {
        // Given
        let error = APIError.invalidResponse
        
        // When
        let description = error.errorDescription
        
        // Then
        XCTAssertNotNil(description, "Error should have a description")
        XCTAssertTrue(description!.contains("invalid") || description!.contains("response"), "Description should mention invalid response")
    }
    
    // MARK: - API Error Response Parsing Tests (Requirement 13.1)
    
    func testGeneratePortrait_When400Error_ThrowsAPIError() async {
        // Given
        let testImage = createTestImage()
        let errorResponse = ErrorResponse(message: "Invalid request parameters")
        let errorData = try! JSONEncoder().encode(errorResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, errorData)
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.apiError")
        } catch let error as APIError {
            if case .apiError(let code, let message) = error {
                XCTAssertEqual(code, 400, "Should capture status code")
                XCTAssertEqual(message, "Invalid request parameters", "Should parse error message from response")
            } else {
                XCTFail("Should throw apiError, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_When401Error_ThrowsAPIError() async {
        // Given
        let testImage = createTestImage()
        let errorResponse = ErrorResponse(message: "Invalid API key")
        let errorData = try! JSONEncoder().encode(errorResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, errorData)
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.apiError")
        } catch let error as APIError {
            if case .apiError(let code, let message) = error {
                XCTAssertEqual(code, 401, "Should capture 401 status code")
                XCTAssertEqual(message, "Invalid API key", "Should parse error message")
            } else {
                XCTFail("Should throw apiError, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_When429RateLimited_ThrowsAPIError() async {
        // Given
        let testImage = createTestImage()
        let errorResponse = ErrorResponse(message: "Rate limit exceeded")
        let errorData = try! JSONEncoder().encode(errorResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, errorData)
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.apiError")
        } catch let error as APIError {
            if case .apiError(let code, let message) = error {
                XCTAssertEqual(code, 429, "Should capture 429 status code")
                XCTAssertEqual(message, "Rate limit exceeded", "Should parse rate limit message")
            } else {
                XCTFail("Should throw apiError, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_When500Error_ThrowsAPIError() async {
        // Given
        let testImage = createTestImage()
        let errorResponse = ErrorResponse(message: "Internal server error")
        let errorData = try! JSONEncoder().encode(errorResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, errorData)
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.apiError")
        } catch let error as APIError {
            if case .apiError(let code, let message) = error {
                XCTAssertEqual(code, 500, "Should capture 500 status code")
                XCTAssertEqual(message, "Internal server error", "Should parse server error message")
            } else {
                XCTFail("Should throw apiError, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_When503ServiceUnavailable_ThrowsAPIError() async {
        // Given
        let testImage = createTestImage()
        let errorResponse = ErrorResponse(message: "Service temporarily unavailable")
        let errorData = try! JSONEncoder().encode(errorResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, errorData)
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.apiError")
        } catch let error as APIError {
            if case .apiError(let code, let message) = error {
                XCTAssertEqual(code, 503, "Should capture 503 status code")
                XCTAssertEqual(message, "Service temporarily unavailable", "Should parse service unavailable message")
            } else {
                XCTFail("Should throw apiError, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_WhenErrorWithoutJSONBody_UsesFallbackMessage() async {
        // Given
        let testImage = createTestImage()
        let invalidData = "Not JSON".data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, invalidData)
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.apiError")
        } catch let error as APIError {
            if case .apiError(let code, let message) = error {
                XCTAssertEqual(code, 500, "Should capture status code")
                XCTAssertTrue(message.contains("500"), "Fallback message should include status code")
            } else {
                XCTFail("Should throw apiError, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_APIError_UsesMessageFromResponse() async {
        // Given
        let testImage = createTestImage()
        let customMessage = "Custom error message from API"
        let errorResponse = ErrorResponse(message: customMessage)
        let errorData = try! JSONEncoder().encode(errorResponse)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, errorData)
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw error")
        } catch let error as APIError {
            let description = error.errorDescription
            XCTAssertEqual(description, customMessage, "Error description should use message from API response")
        } catch {
            XCTFail("Should throw APIError")
        }
    }

    
    // MARK: - Image Conversion Error Tests
    
    func testGeneratePortrait_WhenResponseNotValidImage_ThrowsImageConversionError() async {
        // Given
        let testImage = createTestImage()
        let invalidImageData = "This is not image data".data(using: .utf8)!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, invalidImageData)
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.imageConversionError")
        } catch let error as APIError {
            if case .imageConversionError = error {
                // Expected
            } else {
                XCTFail("Should throw imageConversionError, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_WhenResponseIsEmptyData_ThrowsImageConversionError() async {
        // Given
        let testImage = createTestImage()
        let emptyData = Data()
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, emptyData)
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.imageConversionError")
        } catch let error as APIError {
            if case .imageConversionError = error {
                // Expected
            } else {
                XCTFail("Should throw imageConversionError for empty data, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_WhenResponseIsCorruptedImageData_ThrowsImageConversionError() async {
        // Given
        let testImage = createTestImage()
        // Create corrupted image data (valid PNG header but corrupted body)
        var corruptedData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG header
        corruptedData.append(contentsOf: [0xFF, 0xFF, 0xFF, 0xFF]) // Invalid data
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, corruptedData)
        }
        
        // When/Then
        do {
            _ = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
            XCTFail("Should throw APIError.imageConversionError")
        } catch let error as APIError {
            if case .imageConversionError = error {
                // Expected
            } else {
                XCTFail("Should throw imageConversionError for corrupted data, got \(error)")
            }
        } catch {
            XCTFail("Should throw APIError, got \(error)")
        }
    }
    
    func testGeneratePortrait_ImageConversionError_HasUserFriendlyDescription() {
        // Given
        let error = APIError.imageConversionError
        
        // When
        let description = error.errorDescription
        
        // Then
        XCTAssertNotNil(description, "Error should have a description")
        XCTAssertTrue(description!.contains("image") || description!.contains("process"), "Description should mention image processing")
    }
    
    // MARK: - Edge Cases
    
    func testGeneratePortrait_WithEmptyStylePrompt_SendsRequest() async throws {
        // Given
        let testImage = createTestImage()
        let responseImageData = createValidImageData()
        var capturedRequest: URLRequest?
        
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseImageData)
        }
        
        // When
        _ = try await sut.generatePortrait(image: testImage, stylePrompt: "")
        
        // Then
        XCTAssertNotNil(capturedRequest, "Should send request even with empty prompt")
        let bodyData = MockURLProtocol.capturedBodyData ?? Data()
        let promptFieldMarker = "name=\"prompt\"".data(using: .utf8)!
        XCTAssertTrue(bodyData.range(of: promptFieldMarker) != nil, "Should include prompt field even when empty")
    }
    
    func testGeneratePortrait_WithSpecialCharactersInPrompt_SendsCorrectly() async throws {
        // Given
        let testImage = createTestImage()
        let specialPrompt = "watercolor style with émojis 🐕 & special chars <>&\""
        let responseImageData = createValidImageData()
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseImageData)
        }
        
        // When
        _ = try await sut.generatePortrait(image: testImage, stylePrompt: specialPrompt)
        
        // Then
        let bodyData = MockURLProtocol.capturedBodyData ?? Data()
        let emojisMarker = "émojis".data(using: .utf8)!
        let dogEmojiMarker = "🐕".data(using: .utf8)!
        
        XCTAssertTrue(bodyData.range(of: emojisMarker) != nil, "Should handle special characters")
        XCTAssertTrue(bodyData.range(of: dogEmojiMarker) != nil, "Should handle emojis")
    }
    
    func testGeneratePortrait_WithLongStylePrompt_SendsCorrectly() async throws {
        // Given
        let testImage = createTestImage()
        let longPrompt = String(repeating: "watercolor style ", count: 100)
        let responseImageData = createValidImageData()
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseImageData)
        }
        
        // When
        _ = try await sut.generatePortrait(image: testImage, stylePrompt: longPrompt)
        
        // Then
        let bodyData = MockURLProtocol.capturedBodyData ?? Data()
        let longPromptMarker = longPrompt.data(using: .utf8)!
        XCTAssertTrue(bodyData.range(of: longPromptMarker) != nil, "Should handle long prompts")
    }
    
    func testGeneratePortrait_SuccessfulResponse_ReturnsCorrectImageSize() async throws {
        // Given
        let testImage = createTestImage()
        
        // Create a specific size response image
        let responseSize = CGSize(width: 512, height: 512)
        UIGraphicsBeginImageContext(responseSize)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: responseSize))
        let responseImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let responseImageData = responseImage.pngData()!
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseImageData)
        }
        
        // When
        let result = try await sut.generatePortrait(image: testImage, stylePrompt: "test")
        
        // Then
        XCTAssertEqual(result.size.width, 512, accuracy: 1, "Should return image with correct width")
        XCTAssertEqual(result.size.height, 512, accuracy: 1, "Should return image with correct height")
    }
}


// MARK: - MockURLProtocol

/// A custom URLProtocol for mocking network requests in tests
class MockURLProtocol: URLProtocol {
    
    /// Handler to intercept requests and return mock responses
    static var requestHandler: ((URLRequest) throws -> (URLResponse, Data))?
    
    /// Captured request body data from the stream
    static var capturedBodyData: Data?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("MockURLProtocol.requestHandler must be set before making requests")
        }
        
        // Capture body data from the stream if available
        if let bodyStream = request.httpBodyStream {
            bodyStream.open()
            var bodyData = Data()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer {
                buffer.deallocate()
                bodyStream.close()
            }
            while bodyStream.hasBytesAvailable {
                let bytesRead = bodyStream.read(buffer, maxLength: bufferSize)
                if bytesRead > 0 {
                    bodyData.append(buffer, count: bytesRead)
                }
            }
            MockURLProtocol.capturedBodyData = bodyData
        } else if let httpBody = request.httpBody {
            MockURLProtocol.capturedBodyData = httpBody
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // No-op
    }
}
