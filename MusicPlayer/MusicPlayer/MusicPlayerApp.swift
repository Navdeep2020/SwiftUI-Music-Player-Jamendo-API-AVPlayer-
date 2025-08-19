//
//  MusicPlayerApp.swift
//  MusicPlayer
//
//  Created by Navdeep Singh on 16/08/25.
//

import SwiftUI

@main
struct MusicPlayerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(vm: MusicViewModel())
        }
    }
}
