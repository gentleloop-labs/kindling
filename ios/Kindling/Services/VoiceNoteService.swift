@preconcurrency import AVFoundation
import Foundation
import KindlingCore
import Observation
import SwiftData

@MainActor
@Observable
final class VoiceNoteService: NSObject {
    enum State: Equatable {
        case idle
        case recording
        case paused
        case playing
        case permissionDenied
        case failed
    }

    private(set) var state: State = .idle
    private(set) var elapsed: TimeInterval = 0
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var elapsedTask: Task<Void, Never>?
    private var startedAt: Date?
    private var pendingFilename: String?

    func begin() async {
        guard await permissionGranted() else {
            state = .permissionDenied
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker])
            try session.setActive(true)
            let filename = UUID().uuidString + ".m4a"
            let url = try MemoryFileStore.URL(forRelativePath: filename, in: .voice)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.prepareToRecord()
            guard recorder.record(forDuration: 120) else { throw VoiceError.couldNotRecord }
            self.recorder = recorder
            pendingFilename = filename
            startedAt = .now
            elapsed = 0
            state = .recording
            startElapsedUpdates()
        } catch {
            state = .failed
        }
    }

    func pauseOrResume() {
        guard let recorder else { return }
        if state == .recording {
            recorder.pause()
            elapsedTask?.cancel()
            state = .paused
        } else if state == .paused {
            recorder.record()
            startedAt = Date().addingTimeInterval(-elapsed)
            state = .recording
            startElapsedUpdates()
        }
    }

    func finish(for moment: MemoryMoment, in context: ModelContext) -> VoiceNote? {
        guard let recorder, let filename = pendingFilename else { return nil }
        recorder.stop()
        elapsedTask?.cancel()
        let duration = max(recorder.currentTime, elapsed)
        self.recorder = nil
        pendingFilename = nil
        state = .idle
        guard duration > 0.25 else {
            MemoryFileStore.remove(relativePath: filename, from: .voice)
            return nil
        }
        let note = VoiceNote(relativeFilePath: filename, durationSeconds: duration)
        moment.voiceNotes.append(note)
        try? context.save()
        return note
    }

    func discardRecording() {
        recorder?.stop()
        elapsedTask?.cancel()
        MemoryFileStore.remove(relativePath: pendingFilename, from: .voice)
        recorder = nil
        pendingFilename = nil
        elapsed = 0
        state = .idle
    }

    func play(_ note: VoiceNote) {
        guard let url = try? MemoryFileStore.URL(forRelativePath: note.relativeFilePath, in: .voice) else {
            state = .failed
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            state = .playing
            Task { @MainActor [weak self] in
                guard let duration = self?.player?.duration else { return }
                try? await Task.sleep(for: .seconds(duration))
                if self?.state == .playing { self?.state = .idle }
            }
        } catch {
            state = .failed
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        state = .idle
    }

    func delete(_ note: VoiceNote, from context: ModelContext) {
        MemoryFileStore.remove(relativePath: note.relativeFilePath, from: .voice)
        context.delete(note)
        try? context.save()
    }

    private func permissionGranted() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func startElapsedUpdates() {
        elapsedTask?.cancel()
        elapsedTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, self.state == .recording else { return }
                if let startedAt = self.startedAt {
                    self.elapsed = min(120, Date().timeIntervalSince(startedAt))
                }
                if self.elapsed >= 120 { return }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    private enum VoiceError: Error { case couldNotRecord }
}
