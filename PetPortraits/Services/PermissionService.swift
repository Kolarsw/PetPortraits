//
//  PermissionService.swift
//  PetPortraits
//
//  Created by Kiro
//

import AVFoundation
import Photos

protocol PermissionServiceProtocol {
    func checkCameraPermission() -> PermissionStatus
    func requestCameraPermission() async -> Bool
    func checkPhotoLibraryPermission() -> PermissionStatus
    func requestPhotoLibraryPermission() async -> Bool
}

enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
}

class PermissionService: PermissionServiceProtocol {
    func checkCameraPermission() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
    
    func requestCameraPermission() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
    
    func checkPhotoLibraryPermission() -> PermissionStatus {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
    
    func requestPhotoLibraryPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }
}
