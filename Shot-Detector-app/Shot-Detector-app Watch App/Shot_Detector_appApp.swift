//
//  Shot_Detector_appApp.swift
//  Shot-Detector-app Watch App
//
//  Created by Daniel Trejo on 3/19/25.
//

import SwiftUI
import WatchConnectivity

@main
struct Shot_Detector_app_Watch_AppApp: App {
    @StateObject private var addressDetector = AddressDetector()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(addressDetector)
        }
    }
}
