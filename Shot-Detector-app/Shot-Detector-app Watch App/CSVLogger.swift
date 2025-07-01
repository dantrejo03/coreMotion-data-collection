//
//  CSVLogger.swift
//  Shot-Detector-app Watch App
//
//  Created by Daniel Trejo on 6/23/25.
//

import Foundation

class CSVLogger {
    enum CSVError: Swift.Error { case notOpen }
    
    private let fileName: String
    let fileURL: URL
    private var fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "log-writer", qos: .utility)
    
    init(fileName: String) throws {
        self.fileName = fileName
        let temp = FileManager.default.temporaryDirectory
        self.fileURL = temp.appendingPathComponent(fileName).appendingPathExtension("csv")
        try createFile()
        self.fileHandle = try FileHandle(forWritingTo: fileURL)
        try writeHeader()
    }
    
    private func createFile() throws {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: self.fileURL.path) {
            try fileManager.removeItem(at: self.fileURL)
        }
        fileManager.createFile(atPath: fileURL.path, contents: nil)
    }
    
    private func writeHeader() throws {
        guard let handle = self.fileHandle else { throw CSVError.notOpen }
        let line = "time,accelX,accelY,accelZ,accelMag,rotX,rotY,rotZ,rotMag,roll,pitch,yaw,qw,qx,qy,qz,isAddr\n"
        handle.seekToEndOfFile()
        try handle.write(contentsOf: line.data(using: .utf8)!)
    }
    
    func appendRow(_ sample: AddressDetector.Sample, isAddr: Bool) throws {
        guard let handle = fileHandle else { throw CSVError.notOpen }
        let q = sample.attitudeQuat
        let line = String(format:
            "%.3f," +                   // time
            "%.5f,%.5f,%.5f,%.3f," +    // ax, ay, az, aMag
            "%.5f,%.5f,%.5f,%.3f," +    // rx, ry, rz, wMag
            "%.5f,%.5f,%.5f,"      +    // roll, pitch, yaw
            "%.5f,%.5f,%.5f,%.5f," +    // qw, qx, qy, qz
            "%d\n",                     // isAddr
            sample.time,
            sample.ax, sample.ay, sample.az, sample.aMag,
            sample.rx, sample.ry, sample.rz, sample.wMag,
            sample.roll, sample.pitch, sample.yaw,
            q.w, q.x, q.y, q.z,
            isAddr ? 1 : 0)
        
        queue.async { [handle] in
            handle.seekToEndOfFile()
            try? handle.write(contentsOf: line.data(using: .utf8)!)
        }
    }
    
    func finish() {
        queue.async { [fileHandle] in
            try? fileHandle?.close()
            self.fileHandle = nil
        }
    }
}
