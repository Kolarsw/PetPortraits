//
//  APIModels.swift
//  PetPortraits
//
//  Created by Kiro
//

import UIKit

struct APIRequest {
    let image: UIImage
    let stylePrompt: String
    let apiKey: String
}

struct APIResponse {
    let imageData: Data
}
