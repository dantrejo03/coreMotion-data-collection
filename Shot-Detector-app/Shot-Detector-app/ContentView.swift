//
//  ContentView.swift
//  Shot-Detector-app
//
//  Created by Daniel Trejo on 3/19/25.
//

import SwiftUI

struct ContentView: View {
    let mic = MarkListener()
    @State private var isRecording: Bool = false
    
    // MARK: – Session state placeholders
    @State private var numFilesSaved: Int = 0

    // MARK: – Speech trigger word
    @State private var triggerWord: String = "mark"
    @State private var isHelpPresented = false
    private let maxTriggerLength = 12

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    
                    // Header
                    HStack {
                        Text("Address Detector")
                            .font(.largeTitle.bold())
                        Spacer()
                        Button {
                            isHelpPresented = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .imageScale(.large)
                        }
                        .accessibilityLabel("How to use Address Detector")
                    }
                    .padding(.top, 24)

                    // File counter + reset
                    VStack(spacing: 8) {
                        Text("\(WCBridge.shared.numFilesSaved)")
                            .font(.system(size: 64, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                        Button("Reset Counter") {
                            WCBridge.shared.resetFileCount()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    // Start / Stop buttons
                    HStack(spacing: 24) {
                        Button("Start") {
                            do {
                                try mic.start()
                                isRecording = true
                            } catch {
                                isRecording = false
                            }
                        }
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                        .disabled(isRecording)

                        Button("Stop") {
                            mic.stop()
                            isRecording = false
                        }
                        .controlSize(.large)
                        .buttonStyle(.bordered)
                        .disabled(!isRecording)
                    }

                    // Trigger word section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Speech Trigger Word")
                            .font(.headline)
                        HStack {
                            TextField("e.g. mark", text: $triggerWord)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: .infinity)
                                .onChange(of: triggerWord) { newValue in
                                    // Optional UI‑side length cap
                                    if newValue.count > maxTriggerLength {
                                        triggerWord = String(newValue.prefix(maxTriggerLength))
                                    }
                                }
                            Button("Save") {
                                mic.changeTriggerWord(to: triggerWord)
                            }
                            .disabled(triggerWord.trimmingCharacters(in: .whitespaces).isEmpty || isRecording)
                        }
                        Text("Word must be ≤ \(maxTriggerLength) letters.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Watch connectivity status summary
                    WatchStatusCard()
                        .padding(.top, 8)

                    Spacer(minLength: 0)
                }
                .padding()
            }
            .navigationTitle("")
            .sheet(isPresented: $isHelpPresented) {
                HelpView()
                    .presentationDetents([.large])
            }
        }
    }
}


#Preview {
    ContentView()
}
