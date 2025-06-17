import SwiftUI

struct ContentView: View {
    @State private var publisherName: String = ""
    @State private var extensionName: String = ""
    @State private var version: String = ""
    @State private var targetPlatform: String = "" // Optional

    @State private var isShowingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    @State private var isDownloading: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Extension Details")) {
                    TextField("Publisher Name (e.g., ms-vscode)", text: $publisherName)
                    TextField("Extension Name (e.g., cpptools)", text: $extensionName)
                    TextField("Version (e.g., 1.20.5)", text: $version)
                    TextField("Target Platform (optional, e.g., darwin-arm64)", text: $targetPlatform)
                }

                Section {
                    Button(action: {
                        initiateDownload()
                    }) {
                        HStack {
                            if isDownloading {
                                ProgressView()
                                Text("Downloading...")
                                    .padding(.leading, 5)
                            } else {
                                Image(systemName: "icloud.and.arrow.down")
                                Text("Download VSIX")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isDownloading || publisherName.isEmpty || extensionName.isEmpty || version.isEmpty)
                }
            }
            .navigationTitle("VSIX Downloader")
            .alert(isPresented: $isShowingAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func initiateDownload() {
        // Basic validation
        guard !publisherName.isEmpty, !extensionName.isEmpty, !version.isEmpty else {
            alertTitle = "Missing Information"
            alertMessage = "Please fill in Publisher Name, Extension Name, and Version."
            isShowingAlert = true
            return
        }

        isDownloading = true

        Task {
            let platformToUse = targetPlatform.isEmpty ? nil : targetPlatform
            let (fileURL, error) = await downloadVSIX(
                publisherName: publisherName,
                extensionName: extensionName,
                version: version,
                targetPlatform: platformToUse
            )

            if let error = error {
                alertTitle = "Download Failed"
                // Provide a more user-friendly error message
                switch error {
                case .invalidURL:
                    alertMessage = "The provided information resulted in an invalid URL. Please check the inputs."
                case .networkError(let nsError):
                    alertMessage = "Network error: \(nsError.localizedDescription)"
                case .fileMoveError(let nsError):
                    alertMessage = "Failed to save the file: \(nsError.localizedDescription)"
                case .documentDirectoryNotFound:
                    alertMessage = "Could not access the app's document directory."
                case .invalidResponse:
                    alertMessage = "Received an invalid response from the server."
                }
            } else if let fileURL = fileURL {
                alertTitle = "Download Successful"
                alertMessage = "File saved to: \(fileURL.path)"
            } else {
                // Should not happen if error is nil and fileURL is nil, but as a fallback
                alertTitle = "Unknown Error"
                alertMessage = "An unexpected error occurred during the download."
            }

            isShowingAlert = true
            isDownloading = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
