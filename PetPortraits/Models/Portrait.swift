//
//  Portrait.swift
//  PetPortraits
//
//  Created by Kiro
//

import Foundation

struct Portrait: Identifiable, Codable {
    let id: UUID
    let originalImageData: Data
    let generatedImageData: Data
    let stylePrompt: String
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        originalImageData: Data,
        generatedImageData: Data,
        stylePrompt: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.originalImageData = originalImageData
        self.generatedImageData = generatedImageData
        self.stylePrompt = stylePrompt
        self.createdAt = createdAt
    }
}
