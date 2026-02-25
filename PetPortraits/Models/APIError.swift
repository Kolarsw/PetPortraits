//
//  APIError.swift
//  PetPortraits
//
//  Created by Kiro
//

import Foundation

enum APIError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case apiError(code: Int, message: String)
    case imageConversionError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect to the service. Please check your internet connection."
        case .invalidResponse:
            return "Received an invalid response from the service."
        case .apiError(_, let message):
            return message
        case .imageConversionError:
            return "Unable to process the image."
        }
    }
}

enum PermissionError: LocalizedError {
    case cameraAccessDenied
    case photoLibraryAccessDenied
    
    var errorDescription: String? {
        switch self {
        case .cameraAccessDenied:
            return "Camera access is required to take photos. Please enable it in Settings."
        case .photoLibraryAccessDenied:
            return "Photo library access is required. Please enable it in Settings."
        }
    }
}
