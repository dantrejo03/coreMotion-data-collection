//
//  SharedRecordingModel.swift
//  Shot-Detector-app
//
//  Created by Daniel Trejo on 3/19/25.
//

import AVFoundation

struct SortedRecordings {
    var practice: [URL]
    var real:     [URL]
    var unsorted: [URL]
}

class SharedRecordingModel {
    var audioPlayer: AVAudioPlayer?
    
    func playRecording(_ recording: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording)
            audioPlayer?.play()
        } catch {
            print("Failed to play recording: \(error.localizedDescription)")
        }
    }
    
    func fetchRecordings() -> [URL] {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentPath, includingPropertiesForKeys: nil, options: [])
            let newRecordings = files.filter { $0.pathExtension == "m4a" }
            
            let allRecordings = newRecordings.sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
            
            print("fetched Recording: \(allRecordings)")
            
            return allRecordings
        } catch {
            print("Failed to fetch recordings: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchSortedRecordings() -> SortedRecordings {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentPath, includingPropertiesForKeys: nil, options: [])
            let newRecordings = files.filter { $0.pathExtension == "m4a" }
            
            var practiceRecordings: [URL] = []
            var realRecordings:     [URL] = []
            var unsortedRecordings: [URL] = []
            
            for recording in newRecordings {
                let path = recording.path
                if path.contains("PracticeSwings") {
                    practiceRecordings.append(recording)
                } else if path.contains("RealSwings") {
                    realRecordings.append(recording)
                } else {
                    unsortedRecordings.append(recording)
                }
            }
            
            return SortedRecordings(practice: practiceRecordings, real: realRecordings, unsorted: unsortedRecordings)
        } catch {
            print("Failed to fetch recordings: \(error.localizedDescription)")
            return SortedRecordings(practice: [], real: [], unsorted: [])
        }
    }
    
    func sendRecordingState(_ connectivity: WatchConnectivityManager, _ isRecording: Bool) {
        connectivity.sendStateChangeRequest(isRecording)
    }
}
