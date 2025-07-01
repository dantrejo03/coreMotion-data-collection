//
//  AddressDetector-Simple.swift
//  Shot-Detector-app Watch App
//
//  Created by Daniel Trejo on 6/22/25.
//

import AVFoundation
import CoreMotion
import Combine
import Foundation
import simd
import WatchConnectivity
import WatchKit


// MARK: - Delegate Protocol
protocol AddressDetectorDelegate: AnyObject {
    func detector(_ detector: AddressDetector, didWrite sample: AddressDetector.Sample)
}

class AddressDetector: NSObject, ObservableObject {
    
    // MARK: - Nested Types
    
    struct Sample {
        let time: TimeInterval
        let ax, ay, az: Double
        let rx, ry, rz: Double
        let roll, pitch, yaw: Double
        let attitudeQuat: CMQuaternion
        var aMag: Double { hypot(hypot(ax, ay), az) }
        var wMag: Double { hypot(hypot(rx, ry), rz) }
    }
    
    enum DetectorError: Swift.Error { case noDeviceMotion }
    
    enum Mode: CustomStringConvertible {
        case test, record, attitudeResearch
        var description: String {
            switch self {
            case .test: return "Test"
            case .record: return "Record"
            case .attitudeResearch: return "Attitude Research"
            }
        }
    }
    
    enum State: CustomStringConvertible {
        case address, idle
        var description: String {
            switch self {
            case .address: return "Address"
            case .idle: return "Idle"
            }
        }
    }
    
    
    // MARK: - Public Properties
    
    @Published var accelMag: Double = 0.0
    @Published var rotMag: Double = 0.0
    @Published var roll: Double = 0.0
    @Published var pitch: Double = 0.0
    @Published var yaw: Double = 0.0
    
    weak var delegate: AddressDetectorDelegate?
    
    
    // MARK: - Private Properties
    
    private let MARK_LEN        = 200
    private let motionManager   = CMMotionManager()

    private var inMarkWindow            = false
    private var logger: CSVLogger?
    private var markCountdown           = 0
    private var markNext                = false
    private var q0: simd_quatd?         = nil
    private var ringBuffer: [Sample]    = []
    private var t0                      = Date()
    
    private lazy var slowQ: OperationQueue = {
        let q = OperationQueue()
        q.qualityOfService = .utility
        q.maxConcurrentOperationCount = 1
        return q
    }()
    
    private struct Constants {
        static let lowRateSample:   Double = 100
    }
    
    
    // MARK: Initialization
    
    override init() {
        super.init()
        setupWCSession()
    }
    
    // MARK: - Public API
    
    func start() throws {
        guard motionManager.isDeviceMotionAvailable else { throw DetectorError.noDeviceMotion }
 
        ringBuffer.removeAll(keepingCapacity: true)
        t0 = Date()
        
        let timestamp = Int(t0.timeIntervalSince1970)
        let fileName = "address-collection-\(timestamp)"
        logger = try CSVLogger(fileName: fileName)
        
        self.motionManager.deviceMotionUpdateInterval = 1.0 / Constants.lowRateSample
        self.motionManager.startDeviceMotionUpdates(using: .xTrueNorthZVertical, to: slowQ) { [weak self] (motion, error) in
            guard let self = self, let motion = motion else { return }
            
            if q0 == nil {
                q0 = motion.attitude.quaternion.tosimd()
            }
            self.process(motion)
        }
    }
    
    func stop() {
        self.motionManager.stopDeviceMotionUpdates()
        
        if let logger = logger {
            logger.finish()
            transferCSV(logger.fileURL)
            self.logger = nil
        }
    }
    
    
    // MARK: - Private Helpers
    
    private func process(_ data: CMDeviceMotion) {
        let elapsed = Date().timeIntervalSince(t0)
        let accel = data.userAcceleration
        let rot = data.rotationRate
        
        let sample = Sample(time: elapsed,
                            ax: accel.x, ay: accel.y, az: accel.z,
                            rx: rot.x, ry: rot.y, rz: rot.z,
                            roll: data.attitude.roll, pitch: data.attitude.pitch, yaw: data.attitude.yaw,
                            attitudeQuat: data.attitude.quaternion)
        
        let aMag = sqrt((accel.x * accel.x) + (accel.y * accel.y) + (accel.z * accel.z))
        let wMag = sqrt((rot.x * rot.x) + (rot.y * rot.y) + (rot.z * rot.z))
        
        DispatchQueue.main.async { [weak self] in
            self?.accelMag = aMag
            self?.rotMag = wMag
            self?.roll = sample.roll
            self?.pitch = sample.pitch
            self?.yaw = sample.yaw
        }
        
        recordSample(sample)
    }
    
    private func recordSample(_ sample: Sample) {
        if markCountdown > 0 && inMarkWindow == false {
            inMarkWindow = true
            WKInterfaceDevice.current().play(.start)
        }
        
        let isAddrFlag = markCountdown > 0
        try? logger?.appendRow(sample, isAddr: isAddrFlag)
        delegate?.detector(self, didWrite: sample)
        
        if markCountdown > 0 { markCountdown -= 1 }
        if markCountdown == 0 && inMarkWindow == true {
            inMarkWindow = false
            WKInterfaceDevice.current().play(.stop)
        }
    }
}


extension AddressDetector: WCSessionDelegate {
    private func setupWCSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    func transferCSV(_ fileURL: URL) {
        let session = WCSession.default
        session.transferFile(fileURL, metadata: nil)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard message["cmd"] as? String == "mark" else { return }
        DispatchQueue.main.async {
            self.markCountdown = self.MARK_LEN
            print("Message received from phone")
        }
        
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if error == nil {
            try? FileManager.default.removeItem(at: fileTransfer.file.fileURL)
        } else {
            print("WC transfer error", error!)
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {}
}

