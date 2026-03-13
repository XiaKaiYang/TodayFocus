import Foundation

struct SoundPlaybackRequest: Equatable {
    let assetName: String
    let volume: Double

    init(assetName: String, volume: Double) {
        self.assetName = assetName
        self.volume = min(max(volume, 0), 1)
    }
}

protocol SoundEffectPlaying: AnyObject {
    func play(_ request: SoundPlaybackRequest)
}
