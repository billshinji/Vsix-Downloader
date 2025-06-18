//
//  Extension_DownloaderApp.swift
//  Extension Downloader
//
//  Created by William Shinji on 2025-06-18.
//

import SwiftUI

@main
struct Extension_DownloaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(WindowAccessor())
        }
    }
}
