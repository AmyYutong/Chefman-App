//
//  ChefmanApp.swift
//  ChefmanApp
//
//  Created by 杨雨桐 on 9/14/25.
//

import SwiftUI
import FirebaseCore
import os.log

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Suppress system-level logs in debug mode
        #if DEBUG
        // Set OS_ACTIVITY_MODE to disable verbose system logs
        setenv("OS_ACTIVITY_MODE", "disable", 1)
        #endif
        
        FirebaseApp.configure()
        return true
    }
}

@main
struct ChefmanApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
