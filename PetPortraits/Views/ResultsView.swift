//
//  ResultsView.swift
//  PetPortraits
//
//  Created by Kiro
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: PortraitViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            if let portrait = viewModel.generatedPortrait {
                Image(uiImage: portrait)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(10)
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    Task {
                        await viewModel.refreshPortrait()
                    }
                }) {
                    Text("Refresh")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
                
                Button(action: {
                    viewModel.savePortrait()
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
                
                Button(action: {
                    // Share functionality
                }) {
                    Text("Share")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}
