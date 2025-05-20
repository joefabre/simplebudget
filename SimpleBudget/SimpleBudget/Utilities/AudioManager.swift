import Foundation
import AVFoundation
import Combine

class AudioManager: ObservableObject {
    @Published private(set) var isPlaying = false
    private var player: AVAudioPlayer?
    
    init() {
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func playCashRegisterSound() {
        guard let soundURL = Bundle.main.url(forResource: "cash_register_sound", 
                                         withExtension: "mp3") else {
            print("Could not find sound file")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: soundURL)
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
            
            // Reset isPlaying when sound finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + (player?.duration ?? 0)) {
                self.isPlaying = false
            }
        } catch {
            print("Failed to play sound: \(error)")
        }
    }
    
    func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}

