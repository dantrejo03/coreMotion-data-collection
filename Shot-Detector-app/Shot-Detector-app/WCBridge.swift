//
//  WCBridge.swift
//  Shot-Detector-app
//
//  Created by Daniel Trejo on 6/24/25.
//

import Foundation
import WatchConnectivity

class WCBridge: NSObject, ObservableObject, WCSessionDelegate {
    @Published var numFilesSaved: Int = 0
    static let shared = WCBridge()
    private let session = WCSession.default
    
    // READ-ONLY computed properties
    var isWatchAppInstalled: Bool { session.isWatchAppInstalled }
    var isPaired: Bool { session.isPaired }
    var isReachable: Bool { session.isReachable }
    
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func sendMark() {
        guard WCSession.isSupported() else { return }
        
        if session.isReachable {
            session.sendMessage(["cmd":"mark"], replyHandler: nil) { error in
                print("WC send error:", error.localizedDescription)
            }
        } else {
            print("Watch not reachable")
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Address-Detection", isDirectory: true)
        
        do {
            if !fileManager.fileExists(atPath: dir.path) {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            }
            let dest = dir.appendingPathComponent(file.fileURL.lastPathComponent)
            if fileManager.fileExists(atPath: dest.path) {
                try fileManager.removeItem(at: dest)
            }
            
            try fileManager.moveItem(at: file.fileURL, to: dest)
            DispatchQueue.main.async { [weak self] in
                self?.numFilesSaved += 1
            }
            print("Saved CSV to \(dest.path)")
        } catch {
            print("Error saving csv file")
        }
    }
    
    func resetFileCount() {
        DispatchQueue.main.async { [weak self] in
            self?.numFilesSaved = 0
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if let err = error {
            print("WCSession activation failed:", err)
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
}
