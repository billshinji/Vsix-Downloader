import Foundation

enum DownloadError: Error {
    case invalidURL
    case networkError(Error)
    case fileMoveError(Error)
    case documentDirectoryNotFound
    case invalidResponse
}

func downloadVSIX(
    publisherName: String,
    extensionName: String,
    version: String,
    targetPlatform: String? = nil
) async -> (URL?, DownloadError?) {
    // 1. Construct the download URL
    var components = URLComponents()
    components.scheme = "https"
    components.host = "marketplace.visualstudio.com"

    // Path structure according to the new requirement
    components.path = "/_apis/public/gallery/publishers/\(publisherName)/vsextensions/\(extensionName)/\(version)/vspackage"

    // Add query items if targetPlatform is provided and not empty
    if let platform = targetPlatform, !platform.isEmpty {
        components.queryItems = [URLQueryItem(name: "targetPlatform", value: platform)]
    }

    guard let url = components.url else {
        print("Error: Could not create URL with components: \(components)")
        return (nil, .invalidURL)
    }

    print("Constructed download URL: \(url)")

    // 2. Perform the download
    do {
        let (temporaryURL, response) = try await URLSession.shared.download(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Error: Response is not an HTTPURLResponse")
            return (nil, .invalidResponse)
        }

        // Check if the status code is OK (200).
        // Some package downloads might result in a redirect (302) to the actual asset URL,
        // URLSession's downloadTask typically handles redirects transparently.
        // So, we expect the final response to be 200 if the download (after following redirects) is successful.
        guard httpResponse.statusCode == 200 else {
            print("Error: Invalid HTTP response. Status code: \(httpResponse.statusCode) from URL: \(url)")
            var errorInfo: [String: Any] = [
                NSLocalizedDescriptionKey: "Invalid HTTP response. Status Code: \(httpResponse.statusCode)"
            ]
            // Attempt to read error message from response body if download failed
            if let data = try? Data(contentsOf: temporaryURL), let errorMessage = String(data: data, encoding: .utf8) {
                errorInfo[NSLocalizedFailureReasonErrorKey] = errorMessage
                print("Error response body: \(errorMessage)")
            }
            return (nil, .networkError(NSError(domain: "VSIXDownloader", code: httpResponse.statusCode, userInfo: errorInfo)))
        }

        // 3. Save the file
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not find documents directory")
            return (nil, .documentDirectoryNotFound)
        }

        // Construct filename according to the new format
        let targetPlatformSuffix: String
        if let platform = targetPlatform, !platform.isEmpty {
            targetPlatformSuffix = "@\(platform)"
        } else {
            targetPlatformSuffix = ""
        }
        let destinationFilename = "\(publisherName).\(extensionName)-\(version)\(targetPlatformSuffix).vsix"

        let destinationURL = documentsDirectory.appendingPathComponent(destinationFilename)

        // If a file already exists at destinationURL, remove it.
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
                try FileManager.default.removeItem(at: destinationURL)
                print("Removed existing file at: \(destinationURL.path)")
            } catch {
                print("Error removing existing file: \(error)")
                return (nil, .fileMoveError(error))
            }
        }

        do {
            try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)
            print("File downloaded and saved to: \(destinationURL.path)")
            return (destinationURL, nil)
        } catch {
            print("Error moving downloaded file: \(error)")
            return (nil, .fileMoveError(error))
        }

    } catch {
        print("Error during download session or other pre-move issue for URL \(url): \(error)")
        return (nil, .networkError(error))
    }
}

// Example Usage (requires a context where async functions can be called, e.g., another async function or a Task)
/*
Task {
    // Example 1: Extension without target platform
    let (vscodeVimFileURL, vscodeVimError) = await downloadVSIX(
        publisherName: "vscodevim",
        extensionName: "vim",
        version: "1.27.2" // Use a known recent version
    )

    if let error = vscodeVimError {
        print("VSCodeVim download failed with error: \(error)")
    } else if let fileURL = vscodeVimFileURL {
        print("Successfully downloaded VSCodeVim VSIX to: \(fileURL.path)")
    }

    // Example 2: Extension with a target platform (e.g., C++ tools for macOS ARM64)
    // Note: Actual target platform strings can vary (e.g., 'darwin-arm64', 'win32-x64', 'linux-x64')
    // For C/C++ extension, the assets are often platform-specific.
    let (cppToolsFileURL, cppToolsError) = await downloadVSIX(
        publisherName: "ms-vscode",
        extensionName: "cpptools",
        version: "1.20.5", // Use a known recent version
        targetPlatform: "darwin-arm64"
    )

    if let error = cppToolsError {
        print("C++ tools (darwin-arm64) download failed with error: \(error)")
    } else if let fileURL = cppToolsFileURL {
        print("Successfully downloaded C++ tools (darwin-arm64) VSIX to: \(fileURL.path)")
    }

    // Example 3: Extension with a different target platform (e.g., C++ tools for Windows x64)
    let (cppToolsWinFileURL, cppToolsWinError) = await downloadVSIX(
        publisherName: "ms-vscode",
        extensionName: "cpptools",
        version: "1.20.5", // Use a known recent version
        targetPlatform: "win32-x64"
    )

    if let error = cppToolsWinError {
        print("C++ tools (win32-x64) download failed with error: \(error)")
    } else if let fileURL = cppToolsWinFileURL {
        print("Successfully downloaded C++ tools (win32-x64) VSIX to: \(fileURL.path)")
    }
}
*/
