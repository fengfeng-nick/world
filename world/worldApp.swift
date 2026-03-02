//
//  worldApp.swift
//  world
//
//  Created by nick on 2026/2/27.
//

import SwiftUI

@main
struct worldApp: App {
    @StateObject private var postStorage = PostStorageService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(postStorage)
        }
    }
}
