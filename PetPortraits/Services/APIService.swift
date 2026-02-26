//
//  APIService.swift
//  PetPortraits
//
//  Created by Kiro
//

import UIKit

protocol APIServiceProtocol {
    func generatePortrait(image: UIImage, stylePrompt: String) async throws -> UIImage
}

class APIService: APIServiceProtocol {
    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession
    
    init(
        baseURL: URL = URL(string: "https://api.nanobananapro.google.com")!,
        apiKey: String = "",
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }
    
    func generatePortrait(image: UIImage, stylePrompt: String) async throws -> UIImage {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.imageConversionError
        }
        
        let endpoint = baseURL.appendingPathComponent("v1/generate")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"pet.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add style prompt
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append(stylePrompt.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorData = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw APIError.apiError(code: httpResponse.statusCode, message: errorData.message)
                }
                throw APIError.apiError(code: httpResponse.statusCode, message: "Request failed with status \(httpResponse.statusCode)")
            }
            
            guard let image = UIImage(data: data) else {
                throw APIError.imageConversionError
            }
            
            return image
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
}

struct ErrorResponse: Codable, Sendable {
    let message: String
}
