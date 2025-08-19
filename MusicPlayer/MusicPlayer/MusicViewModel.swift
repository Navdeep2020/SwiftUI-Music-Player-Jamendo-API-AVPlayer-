//
//  ContentView.swift
//  MusicViewModel
//
//  Created by Navdeep Singh on 16/08/25.
//

import Foundation
import Combine
import AVFoundation

struct JamendoResponse: Decodable {
    let results: [Track]
}

struct Track: Decodable {
    let id: String
    let name: String
    let artist_name: String
    let audio: String
    let image: String
    let duration: Int
    let waveform: String
}

struct WaveformData: Decodable {
    let peaks: [Int]
}

class MusicViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var selectedTrack: Track?
    @Published var errorMessage: String?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var waveformPeaks: [Int] = []
    
    private let apiKey = "" // key, please generate your own its free
    @Published var songName = "Happy Nation"

    // keeping the AVPlayer alive
    private var player: AVPlayer?
    private var timeObserver: Any?

    func searchMusic() {
        guard let encodedName = songName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.jamendo.com/v3.0/tracks?client_id=\(apiKey)&namesearch=\(encodedName)&limit=10&format=json") else {
            print("❌ Invalid URL")
            return
        }

        print("🔍 Searching: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error as? URLError {
                DispatchQueue.main.async {
                    self.errorMessage = "URLError: \(error.code.rawValue) \(error.localizedDescription)"
                    print("❌ URLError: \(error.code) \(error.localizedDescription)")
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "Error: No data received"
                    print("❌ Error: No data received")
                }
                return
            }

            do {
                let response = try JSONDecoder().decode(JamendoResponse.self, from: data)
                DispatchQueue.main.async {
                    self.tracks = response.results
                    if let firstTrack = response.results.first {
                        print("🎵 Found \(response.results.count) tracks")
                        print("🎵 First Song: \(firstTrack.name)")
                        print("🎤 Artist: \(firstTrack.artist_name)")
                    } else {
                        print("⚠️ No results found")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "JSON Error: \(error.localizedDescription)"
                    print("❌ JSON Error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    func selectTrack(_ track: Track) {
        // Stop current playback if any
        if isPlaying {
            player?.pause()
            isPlaying = false
            removeTimeObserver()
        }
        
        selectedTrack = track
        parseWaveform(from: track.waveform)
        
        // Start playing the new track
        if let url = URL(string: track.audio) {
            playSong(url: url)
        }
        
        print("🎵 Selected and playing: \(track.name) by \(track.artist_name)")
    }

    func parseWaveform(from waveformString: String) {
        guard let data = waveformString.data(using: .utf8) else { return }
        
        do {
            let waveformData = try JSONDecoder().decode(WaveformData.self, from: data)
            DispatchQueue.main.async {
                self.waveformPeaks = waveformData.peaks
            }
        } catch {
            print("❌ Waveform parsing error: \(error)")
        }
    }

    func playSong(url: URL) {
        // Check if we're playing a different track
        if let currentPlayer = player,
           let currentURL = currentPlayer.currentItem?.asset as? AVURLAsset,
           currentURL.url != url {
            // Different track, create new player
            currentPlayer.pause()
            removeTimeObserver()
            self.player = AVPlayer(url: url)
            self.player?.play()
            isPlaying = true
            addTimeObserver()
        } else if let existingPlayer = player {
            // Same track, toggle play/pause
            if isPlaying {
                existingPlayer.pause()
                isPlaying = false
                removeTimeObserver()
            } else {
                existingPlayer.play()
                isPlaying = true
                addTimeObserver()
            }
        } else {
            // No player exists, create new one
            self.player = AVPlayer(url: url)
            self.player?.play()
            isPlaying = true
            addTimeObserver()
        }
        print("Playing \(url)")
    }
    
    private func addTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
    }
    
    private func removeTimeObserver() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func formatDuration(_ duration: Int) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

