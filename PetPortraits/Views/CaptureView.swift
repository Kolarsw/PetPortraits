//
//  CaptureView.swift
//  PetPortraits
//
//  Created by Kiro
//

import SwiftUI

struct CaptureView: View {
    @ObservedObject var viewModel: PortraitViewModel
    @State private var showErrorAlert = false
    @State private var navigateToResults = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Display selected image
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
                    .accessibilityIdentifier("selectedImage")
            }
            
            Spacer()
            
            // Style prompt text field
            TextField("How should we style your pet?", text: $viewModel.stylePrompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
                .accessibilityIdentifier("stylePromptTextField")
            
            // Generate button with loading state
            Button(action: {
                Task {
                    await viewModel.generatePortrait()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .accessibilityIdentifier("loadingIndicator")
                    }
                    Text("Generate")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.stylePrompt.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.isLoading || viewModel.stylePrompt.isEmpty)
            .padding(.horizontal, 40)
            .accessibilityIdentifier("generateButton")
            
            Spacer()
        }
        .padding()
        .navigationTitle("Style Your Pet")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.errorMessage) { oldValue, newValue in
            showErrorAlert = newValue != nil
        }
        .onChange(of: viewModel.generatedPortrait) { oldValue, newValue in
            if newValue != nil {
                navigateToResults = true
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("Retry", role: .cancel) {
                // Dismiss alert and keep inputs preserved for retry
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
        .navigationDestination(isPresented: $navigateToResults) {
            ResultsView(viewModel: viewModel)
        }
    }
}

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    NavigationStack {
        CaptureView(viewModel: PortraitViewModel())
    }
}
