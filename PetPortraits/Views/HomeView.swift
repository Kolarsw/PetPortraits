//
//  HomeView.swift
//  PetPortraits
//
//  Created by Kiro
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = PortraitViewModel()
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()
                
                Text("Pet Portrait")
                    .font(.largeTitle)
                    .fontWeight(.light)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Button(action: {
                        showCamera = true
                    }) {
                        Text("Take Photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showPhotoPicker = true
                    }) {
                        Text("Choose from Gallery")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .sheet(isPresented: $showCamera) {
                CameraViewController(image: $viewModel.selectedImage)
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerViewController(image: $viewModel.selectedImage)
            }
            .onChange(of: viewModel.selectedImage) { oldValue, newValue in
                if newValue != nil {
                    // Navigate to capture view
                }
            }
        }
    }
}
