//
//  CaptureView.swift
//  PetPortraits
//
//  Created by Kiro
//

import SwiftUI

struct CaptureView: View {
    @ObservedObject var viewModel: PortraitViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
            }
            
            TextField("How should we style your pet?", text: $viewModel.stylePrompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    await viewModel.generatePortrait()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Generate")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.stylePrompt.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(viewModel.isLoading || viewModel.stylePrompt.isEmpty)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .alert(item: Binding(
            get: { viewModel.errorMessage.map { ErrorWrapper(message: $0) } },
            set: { viewModel.errorMessage = $0?.message }
        )) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}
