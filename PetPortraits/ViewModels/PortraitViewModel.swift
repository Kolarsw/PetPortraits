//
//  PortraitViewModel.swift
//  PetPortraits
//
//  Created by Kiro
//

import SwiftUI
import Combine

class PortraitViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var stylePrompt: String = ""
    @Published var generatedPortrait: UIImage?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let apiService: APIServiceProtocol
    private let imageService: ImageServiceProtocol
    private let permissionService: PermissionServiceProtocol
    
    init(
        apiService: APIServiceProtocol = APIService(),
        imageService: ImageServiceProtocol = ImageService(),
        permissionService: PermissionServiceProtocol = PermissionService()
    ) {
        self.apiService = apiService
        self.imageService = imageService
        self.permissionService = permissionService
    }
    
    @MainActor
    func generatePortrait() async {
        guard let image = selectedImage, !stylePrompt.isEmpty else {
            errorMessage = "Please select an image and enter a style prompt."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let portrait = try await apiService.generatePortrait(image: image, stylePrompt: stylePrompt)
            generatedPortrait = portrait
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshPortrait() async {
        guard let image = selectedImage, !stylePrompt.isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let portrait = try await apiService.generatePortrait(image: image, stylePrompt: stylePrompt)
            generatedPortrait = portrait
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func savePortrait() {
        guard let portrait = generatedPortrait else {
            errorMessage = "No portrait to save."
            return
        }
        
        Task {
            do {
                try await imageService.saveToPhotoLibrary(portrait)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func sharePortrait() -> [Any] {
        guard let portrait = generatedPortrait else {
            return []
        }
        return [portrait]
    }
}
