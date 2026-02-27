# Future Enhancements & Technical Notes

## Testing Improvements

### Property-Based Testing with SwiftCheck

SwiftCheck is already added to the project. Use it for pure utility functions:

```swift
// Good candidates for PBT:
// - Input sanitization
// - Data transformations
// - Validation logic
// - Serialization/deserialization

import SwiftCheck

func testProperty() {
    property("description") <- forAll { (input: Type) in
        // return Bool
    }
}
```

Avoid using SwiftCheck with `@MainActor` types or async code — it causes deadlocks.

---

## Recommended Utility Functions

### 1. Prompt Sanitizer

Sanitize user input before sending to API:

```swift
struct PromptSanitizer {
    static let maxLength = 200
    
    static func sanitize(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .prefix(maxLength)
            .description
    }
    
    static func isValid(_ input: String) -> Bool {
        let sanitized = sanitize(input)
        return !sanitized.isEmpty && sanitized.count >= 3
    }
}
```

### 2. Image Compressor

Reduce image size before API upload to save bandwidth:

```swift
struct ImageCompressor {
    static let maxDimension: CGFloat = 1024
    static let compressionQuality: CGFloat = 0.8
    
    static func compress(_ image: UIImage) -> Data? {
        let resized = resize(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: compressionQuality)
    }
    
    static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        
        guard ratio < 1 else { return image }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized ?? image
    }
}
```

### 3. Rate Limiter

Prevent API abuse and excessive requests:

```swift
actor RateLimiter {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval
    
    init(minimumInterval: TimeInterval = 2.0) {
        self.minimumInterval = minimumInterval
    }
    
    func canMakeRequest() -> Bool {
        guard let last = lastRequestTime else { return true }
        return Date().timeIntervalSince(last) >= minimumInterval
    }
    
    func recordRequest() {
        lastRequestTime = Date()
    }
    
    func timeUntilNextRequest() -> TimeInterval {
        guard let last = lastRequestTime else { return 0 }
        let elapsed = Date().timeIntervalSince(last)
        return max(0, minimumInterval - elapsed)
    }
}
```

---

## Security Enhancements

### 1. API Key Storage

Never hardcode API keys. Use Keychain:

```swift
import Security

struct KeychainHelper {
    static func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
    
    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
}
```

### 2. Certificate Pinning

Prevent man-in-the-middle attacks:

```swift
class PinnedURLSessionDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertificateHash: String
    
    init(pinnedHash: String) {
        self.pinnedCertificateHash = pinnedHash
    }
    
    func urlSession(_ session: URLSession, 
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let serverCertData = SecCertificateCopyData(certificate) as Data
        let serverHash = serverCertData.sha256Hash // implement hash extension
        
        if serverHash == pinnedCertificateHash {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

### 3. Input Validation

Validate all user inputs:

```swift
struct InputValidator {
    enum ValidationError: LocalizedError {
        case empty
        case tooShort(minimum: Int)
        case tooLong(maximum: Int)
        case containsProhibitedContent
        
        var errorDescription: String? {
            switch self {
            case .empty: return "Input cannot be empty"
            case .tooShort(let min): return "Input must be at least \(min) characters"
            case .tooLong(let max): return "Input cannot exceed \(max) characters"
            case .containsProhibitedContent: return "Input contains prohibited content"
            }
        }
    }
    
    static func validatePrompt(_ prompt: String) throws -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else { throw ValidationError.empty }
        guard trimmed.count >= 3 else { throw ValidationError.tooShort(minimum: 3) }
        guard trimmed.count <= 200 else { throw ValidationError.tooLong(maximum: 200) }
        
        // Add content filtering as needed
        
        return trimmed
    }
}
```

---

## Feature Ideas

### Portrait History
- Store generated portraits locally with Core Data or SwiftData
- Allow users to browse and re-share past creations
- Implement swipe-to-delete

### Style Presets
- Predefined style prompts (Watercolor, Oil Painting, Cartoon, etc.)
- Quick-select buttons on capture screen
- User can still customize with text input

### Batch Processing
- Select multiple photos
- Apply same style to all
- Progress indicator for batch operations

### Social Features
- Share directly to Instagram/TikTok
- Add watermark option
- Generate shareable links

### Offline Mode
- Cache last successful API response
- Show cached results when offline
- Queue requests for when connection returns

---

## Performance Optimizations

### Image Caching
```swift
actor ImageCache {
    private var cache = NSCache<NSString, UIImage>()
    
    func get(key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }
    
    func set(key: String, image: UIImage) {
        cache.setObject(image, forKey: key as NSString)
    }
}
```

### Background Processing
- Use `BGTaskScheduler` for deferred uploads
- Process images in background when app is suspended

---

## Notes

- SwiftCheck is installed but currently unused (removed from ViewModel tests due to @MainActor incompatibility)
- ResultsViewUITests are skipped until real API is configured
- API key storage needs implementation before App Store release
