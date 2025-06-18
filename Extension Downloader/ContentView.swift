import SwiftUI

struct ContentView: View {
    @State private var publisherName: String = ""
    @State private var extensionName: String = ""
    @State private var version: String = ""
    @State private var targetPlatform: String = "" // Optional
    @State private var logMessages: String = ""

    @State private var isDownloading: Bool = false

    var body: some View {
        Form {
            Section(header: Text("Fill in the info and get the VSIX")) {
                TextField("Publisher Name", text: $publisherName, prompt: Text("ms-vscode"))
                TextField("Extension Name", text: $extensionName, prompt: Text("cpptools"))
                TextField("Version", text: $version, prompt: Text("1.20.5"))
                TextField("Target Platform", text: $targetPlatform, prompt: Text("darwin-arm64 (optional)"))
            }

            Section {
                Button(action: initiateDownload) {
                    HStack {
                        if isDownloading {
                            ProgressView()
                                .scaleEffect(0.4, anchor: .center)
                                .frame(width: 12, height: 12)
                            Text("Downloading...")
                                .padding(.leading, 5)
                        } else {
                            Image(systemName: "icloud.and.arrow.down")
                            Text("Download VSIX")
                        }
                    }
                }
                .disabled(isDownloading || publisherName.isEmpty || extensionName.isEmpty || version.isEmpty)
                VStack(alignment: .leading) {
                    TextEditor(text: $logMessages)
                        .frame(minHeight: 100)
                        .font(.system(.body, design: .monospaced))
                        .border(Color.gray, width: 1)
                        .disabled(true)
                    Text("Engine made by Han Kyeol Kim, UI by William, 2025, free to use. Happy coding! :-)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("VSIX Downloader")
        .padding(10)
        .frame(minWidth: 400)
    }

    private func initiateDownload() {
        // Basic validation
        guard !publisherName.isEmpty, !extensionName.isEmpty, !version.isEmpty else {
            logMessages += "[ERROR] Please fill in Publisher Name, Extension Name, and Version.\n"
            return
        }

        isDownloading = true
        logMessages += "[INFO] Starting download...\n"

        Task {
            let platformToUse = targetPlatform.isEmpty ? nil : targetPlatform
            let (fileURL, error) = await downloadVSIX(
                publisherName: publisherName,
                extensionName: extensionName,
                version: version,
                targetPlatform: platformToUse
            )

            if let error = error {
                // Provide a more user-friendly error message
                switch error {
                case .invalidURL:
                    logMessages += "[ERROR] The provided information resulted in an invalid URL. Please check the inputs.\n"
                case .networkError(let nsError):
                    logMessages += "[ERROR] Network error: \(nsError.localizedDescription)\n"
                case .fileMoveError(let nsError):
                    logMessages += "[ERROR] Failed to save the file: \(nsError.localizedDescription)\n"
                case .documentDirectoryNotFound:
                    logMessages += "[ERROR] Could not access the app's document directory.\n"
                case .invalidResponse:
                    logMessages += "[ERROR] Received an invalid response from the server.\n"
                }
            } else if let fileURL = fileURL {
                logMessages += "[SUCCESS] File saved to: \(fileURL.path)\n"
            } else {
                // Should not happen if error is nil and fileURL is nil, but as a fallback
                logMessages += "[ERROR] An unexpected error occurred during the download.\n"
            }

            isDownloading = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
