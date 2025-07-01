//
//  HelpView.swift
//  Shot-Detector-app
//
//  Created by Daniel Trejo on 6/30/25.
//

import SwiftUI

struct HelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .frame(width: 40, height: 4)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            Text("How to Use Address Detector")
                .font(.title2.bold())
            Group {
                Text("1. Press **Start** and **Stop** to toggle the microphone.")
                Text("2. Say your trigger word (default \"mark\" while setting up to swing. You can change this word, but must keep it under 12 characters.")
                Text("3. The watch will perform two haptic notifications. Once at the start, and again at the end of a 2 second window. The 'isAddr' column of the csv will have a value of 1 during this window and 0 everywhere else.")
                Text("3. When you press stop the watch sends a CSV file to your phone. They will be in a folder labeled **Address-Detection**")
                Text("4. The number displays the number of files recorded in a session, not the total number of files in your folder. You can reset this counter whenever you want.")
                Text("5. Make sure the Apple Watch app shows *Installed*, *Paired*, and *Reachable* before starting.")
            }
            .font(.body)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    HelpView()
}
