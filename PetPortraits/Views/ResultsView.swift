//
//  ResultsView.swift
//  PetPortraits
//
//  Created by Kiro
//

import SwiftUI

/// UIViewControllerRepresentable wrapper for UIActivityViewController
/// Used to present the native iOS share sheet
/// Requirements: 10.1, 10.2, 10.3
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}

/// ResultsView displays the AI-generated portrait with action buttons
/// Requirements: 1.1, 1.2, 1.3, 6.2, 6.3, 8.1, 9.1, 10.1, 10.2, 10.3, 13.1, 13.2, 13.3, 13.4, 13.5
struct ResultsView: View {
    @ObservedObject var viewModel: PortraitViewModel
    @State private var showShareSheet = false
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Display generated portrait
            // Requirements: 6.2
            if let portrait = viewModel.generatedPortrait {
                Image(uiImage: portrait)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(10)
                    .accessibilityIdentifier("generatedPortrait")
            }
            
            // Loading animation during refresh
            // Requirements: 7.2, 7.3
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .accessibilityIdentifier("loadingIndicator")
            }
            
            Spacer()
            
            // Action buttons
            // Requirements: 6.3, 8.1, 9.1, 10.1
            HStack(spacing: 20) {
                // Refresh button
                // Requirements: 8.1
                Button(action: {
                    Task {
                        await viewModel.refreshPortrait()
                    }
                }) {
                    Text("Refresh")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isLoading ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("refreshButton")
                
                // Save button
                // Requirements: 9.1
                Button(action: {
                    viewModel.savePortrait()
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isLoading ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("saveButton")
                
                // Share button
                // Requirements: 10.1
                Button(action: {
                    showShareSheet = true
                }) {
                    Text("Share")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isLoading ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("shareButton")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Your Portrait")
        .navigationBarTitleDisplayMode(.inline)
        // Share sheet presentation
        // Requirements: 10.1, 10.2, 10.3
        .sheet(isPresented: $showShareSheet) {
            let items = viewModel.sharePortrait()
            if !items.isEmpty {
                ActivityViewController(activityItems: items)
            }
        }
        // Error handling
        // Requirements: 13.1, 13.2, 13.3, 13.4, 13.5
        .onChange(of: viewModel.errorMessage) { oldValue, newValue in
            showErrorAlert = newValue != nil
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                // Dismiss alert and preserve state for retry
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
    }
}

#Preview {
    NavigationStack {
        ResultsView(viewModel: {
            let vm = PortraitViewModel()
            // Create a sample image for preview
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
            vm.generatedPortrait = renderer.image { context in
                UIColor.systemBlue.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
            }
            return vm
        }())
    }
}
