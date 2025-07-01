//
//  MarkListener.swift
//  Shot-Detector-app
//
//  Created by Daniel Trejo on 6/24/25.
//

import AVFoundation
import Speech

final class MarkListener: NSObject {

    private let engine     = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!

    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task:     SFSpeechRecognitionTask?
    private var tapInstalled = false
    
    private var triggerWord: String = "mark"
   

    // MARK: 1. Ask for BOTH permissions, THEN start
    func start() throws {
        try requestPermission()
    }
    
    private func requestPermission() throws {
        AVAudioSession.sharedInstance().requestRecordPermission { micOK in
            guard micOK else { return }

            SFSpeechRecognizer.requestAuthorization { speechStatus in
                guard speechStatus == .authorized else { return }
                DispatchQueue.main.async { try? self.turnOnMic() }
            }
        }
    }

    // MARK: 2. Start mic + speech recognizer
    func turnOnMic() throws {
        guard task == nil else { return }          // already running

        // ---- audio session ----
        let sess = AVAudioSession.sharedInstance()
        try sess.setCategory(.record, mode: .measurement, options: .duckOthers)
        try sess.setActive(true, options: .notifyOthersOnDeactivation)

        // ---- recognizer ----
        request = SFSpeechAudioBufferRecognitionRequest()
        request!.shouldReportPartialResults = true

        task = recognizer.recognitionTask(with: request!) { [weak self] result, error in
            guard let self, let text = result?.bestTranscription.formattedString.lowercased()
            else { return }

            if text.contains(self.triggerWord) {
                WCBridge.shared.sendMark()
                self.restartRecognizer()
                return
            }
            
            else if error != nil || result?.isFinal == true {
                self.restartRecognizer()
            }
        }

        // ---- mic tap ----
        let input = engine.inputNode
        let fmt   = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: fmt) { [weak self] buf, _ in
            self?.request?.append(buf)            // always non-nil now
        }
        tapInstalled = true

        engine.prepare()
        try engine.start()
    }

    // MARK: 3. Stop everything
    func stop() {
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        engine.stop()

        request?.endAudio()
        task?.cancel()
        task  = nil
        request = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func changeTriggerWord(to word: String) {
        let newWord = word.prefix(12).lowercased()
        self.triggerWord = newWord
    }

    private func restartRecognizer(after delay: TimeInterval = 0.5) {
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.request = SFSpeechAudioBufferRecognitionRequest()
            self.request!.shouldReportPartialResults = true

            self.task = self.recognizer.recognitionTask(with: self.request!) { [weak self]
                result, error in
                guard let self, let text = result?.bestTranscription.formattedString.lowercased()
                else { return }

                if text.contains(self.triggerWord) {
                    WCBridge.shared.sendMark()
                    self.restartRecognizer()
                }
            }
        }
    }
}
