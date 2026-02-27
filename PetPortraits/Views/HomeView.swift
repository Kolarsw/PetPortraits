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
    @State private var navigateToCaptureView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // App title with minimalist styling
                Text("Pet Portrait")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .accessibilityIdentifier("appTitle")
                
                Spacer()
                
                // Action buttons with ample white space
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
                    .accessibilityIdentifier("takePhotoButton")
                    
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
                    .accessibilityIdentifier("chooseFromGalleryButton")
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
                    navigateToCaptureView = true
                }
            }
            .navigationDestination(isPresented: $navigateToCaptureView) {
                CaptureView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    HomeView()
}
