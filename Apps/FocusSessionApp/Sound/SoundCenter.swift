import AVFoundation
import Foundation

final class SoundCenter: NSObject, ObservableObject, SoundEffectPlaying {
    private var loopPlayer: AVAudioPlayer?
    private var oneShotPlayers: [AVAudioPlayer] = []

    func play(_ request: SoundPlaybackRequest) {
        guard let url = Self.audioFileURL(named: request.assetName) else {
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = Float(request.volume)
            player.prepareToPlay()
            player.play()
            oneShotPlayers.append(player)
        } catch {
            return
        }
    }

    func startLoop(named assetName: String, volume: Double) {
        guard let url = Self.audioFileURL(named: assetName) else {
            stopLoop()
            return
        }

        if loopPlayer?.url == url {
            loopPlayer?.volume = Float(min(max(volume, 0), 1))
            if loopPlayer?.isPlaying == false {
                loopPlayer?.play()
            }
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Float(min(max(volume, 0), 1))
            player.prepareToPlay()
            player.play()
            loopPlayer = player
        } catch {
            loopPlayer = nil
        }
    }

    func stopLoop() {
        loopPlayer?.stop()
        loopPlayer = nil
    }

    private static func audioFileURL(named assetName: String) -> URL? {
        guard let audioRoot = Bundle.main.resourceURL?.appendingPathComponent("Audio", isDirectory: true) else {
            return nil
        }

        let enumerator = FileManager.default.enumerator(
            at: audioRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        while let candidate = enumerator?.nextObject() as? URL {
            guard candidate.lastPathComponent == assetName else {
                continue
            }
            return candidate
        }

        return nil
    }
}
