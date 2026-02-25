//
//  ImageService.swift
//  PetPortraits
//
//  Created by Kiro
//

import UIKit
import Photos

protocol ImageServiceProtocol {
    func saveToPhotoLibrary(_ image: UIImage) async throws
}

class ImageService: ImageServiceProtocol {
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        guard status == .authorized else {
            if status == .notDetermined {
                let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard newStatus == .authorized else {
                    throw PermissionError.photoLibraryAccessDenied
                }
                return try await performSave(image)
            } else {
                throw PermissionError.photoLibraryAccessDenied
            }
        }
        
        try await performSave(image)
    }
    
    private func performSave(_ image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}
