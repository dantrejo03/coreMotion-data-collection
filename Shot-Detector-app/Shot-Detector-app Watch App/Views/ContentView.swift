//
//  ContentView.swift
//  Shot-Detector-app Watch App
//
//  Created by Daniel Trejo on 3/19/25.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject var addressDetector: AddressDetector
    @State var isRecording: Bool = false
    @State var settingsView: Bool = false
    
    var body: some View {
        VStack {
            
            Text("Accel: \(addressDetector.accelMag)")
            Text("Rot: \(addressDetector.rotMag)")
            Text("Roll: \(addressDetector.roll)")
            Text("Pitch: \(addressDetector.pitch)")
            Text("Yaw: \(addressDetector.yaw)")
            
            Spacer()
            
            HStack {
                Button("Start") {
                    do {
                        try addressDetector.start()
                        isRecording = true
                    } catch {
                        isRecording = false
                    }
                }
                .disabled(isRecording)
                
                Button("Stop") {
                    addressDetector.stop()
                    isRecording = false
                }
                .disabled(!isRecording)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AddressDetector())
}
