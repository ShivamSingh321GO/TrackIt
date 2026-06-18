//
//  TrackItApp.swift
//  TrackIt
//
//  Created by shivam kumar singh on 6/3/26.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // App is now natively configured as LSUIElement in project.pbxproj
    }
}

@main
struct TrackItApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
