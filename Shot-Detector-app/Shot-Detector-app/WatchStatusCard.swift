//
//  WatchStatusCard.swift
//  Shot-Detector-app
//
//  Created by Daniel Trejo on 6/30/25.
//

import SwiftUI

struct WatchStatusCard: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusRow(label: "App Installed",     isGood: WCBridge.shared.isWatchAppInstalled)
            statusRow(label: "Watch Paired",      isGood: WCBridge.shared.isPaired)
            statusRow(label: "Reachable",         isGood: WCBridge.shared.isReachable)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 4)
    }

    @ViewBuilder
    private func statusRow(label: String, isGood: Bool) -> some View {
        Label(label, systemImage: isGood ? "checkmark.circle.fill" : "xmark.circle.fill")
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(isGood ? .green : .red)
    }
}

