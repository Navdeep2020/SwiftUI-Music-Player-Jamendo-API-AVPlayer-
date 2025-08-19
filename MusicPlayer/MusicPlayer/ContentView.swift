//
//  ContentView.swift
//  MusicPlayer
//
//  Created by Navdeep Singh on 16/08/25.
//

import SwiftUI
import Foundation
import Combine
import AVFoundation
import PhotosUI

struct ContentView: View {
    @StateObject var vm = MusicViewModel()
    @State private var searchText: String = ""

    var body: some View {
        TabView {
            VStack(spacing: 0) {
               
                SearchView(searchText: $searchText, vm: vm)
                    .padding(.top, 20)
                
                // Search results or selected track
                if !vm.tracks.isEmpty {
                    SearchResultsView(tracks: vm.tracks, vm: vm)
                        .padding(.top, 20)
                } else if let selectedTrack = vm.selectedTrack {
                    TrackCard(track: selectedTrack, vm: vm)
                        .padding(.top, 20)
                }
                
                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
                
                Spacer()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }

            MusicView(vm: vm)
                .tabItem {
                    Image(systemName: "music.note")
                    Text("Music")
                }
                
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
        .accentColor(.orange)
    }
}

// MARK: SearchView
struct SearchView: View {
    @Binding var searchText: String
    @ObservedObject var vm: MusicViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            
            Text("🎵 Musefy")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // Tried: Native iOS-style search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search for a song...", text: $searchText)
                    .font(.system(size: 17))
                    .onSubmit {
                        vm.songName = searchText
                        vm.searchMusic()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
    }
}

struct MusicView: View {
    @ObservedObject var vm: MusicViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient for full app
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if let track = vm.selectedTrack {
                    FullPlayerView(track: track, vm: vm)
                } else {
                    VStack {
                        Image(systemName: "music.note")
                            .font(.system(size: 100))
                            .foregroundColor(.gray)
                        Text("No track selected")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: FullPlayerView
struct FullPlayerView: View {
    let track: Track
    @ObservedObject var vm: MusicViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Album Art
            AsyncImage(url: URL(string: track.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 150)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 300, height: 300)
            .clipShape(Circle())
            .padding(.top, 30)
            
            VStack(spacing: 10) {
                HStack {
                    Button(action: {}) {
                        Image(systemName: "heart")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(track.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(track.artist_name)
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 30)
                
                // Waveform
                WaveformView(peaks: vm.waveformPeaks, currentTime: vm.currentTime, duration: track.duration)
                    .frame(height: 60)
                    .padding(.horizontal, 30)
                
                HStack {
                    Text(vm.formatTime(vm.currentTime))
                        .foregroundColor(.white)
                        .font(.caption)
                    
                    Spacer()
                    
                    Text(vm.formatDuration(track.duration))
                        .foregroundColor(.white)
                        .font(.caption)
                }
                .padding(.horizontal, 30)
                
                // Playback Controls will do on next weekend
                HStack(spacing: 40) {
                    Button(action: {}) {
                        Image(systemName: "shuffle")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "backward.end.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Button(action: {
                        if let url = URL(string: track.audio) {
                            vm.playSong(url: url)
                        }
                    }) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.red]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                            )
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "forward.end.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "repeat")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .padding(.top, 20)
            }
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

// MARK: WaveformView
struct WaveformView: View {
    let peaks: [Int]
    let currentTime: TimeInterval
    let duration: Int
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(peaks.enumerated()), id: \.offset) { index, peak in
                let normalizedPeak = Double(peak) / 100.0
                let isActive = Double(index) / Double(peaks.count) < (currentTime / Double(duration))
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(isActive ? Color.orange : Color.white.opacity(0.5))
                    .frame(width: 2, height: max(6, CGFloat(normalizedPeak) * 60))
                    .animation(.easeInOut(duration: 0.2), value: isActive)
            }
        }
    }
}

struct TrackCard: View {
    let track: Track
    @ObservedObject var vm: MusicViewModel
    
    var body: some View {
        VStack(spacing: 15) {
            AsyncImage(url: URL(string: track.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(spacing: 5) {
                Text(track.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(track.artist_name)
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            // Waveform preview
            if !vm.waveformPeaks.isEmpty {
                WaveformView(peaks: vm.waveformPeaks, currentTime: vm.currentTime, duration: track.duration)
                    .frame(height: 40)
                    .padding(.horizontal)
            }
            
            Button(action: {
                if let url = URL(string: track.audio) {
                    vm.playSong(url: url)
                }
            }) {
                HStack {
                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                    Text(vm.isPlaying ? "Pause" : "Play")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange, Color.red]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(radius: 5)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}

// MARK: ProfileView
struct ProfileView: View {
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showFullScreen = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
 
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        .onTapGesture {
                            showFullScreen = true
                        }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(Text("Pick").foregroundColor(.black))
                }
                
                PhotosPicker("Edit", selection: $selectedItem, matching: .images)
                    .padding(.horizontal, 10)
                
     
                List {
                    Text("Name: Navdeep")
                    Text("Age: 24")
                    Text("Taste: Techno")
                    Text("Loc: India")
                    Text("Average hours: 4.2")
                    
                    Button {
                        // theme color change
                    } label: {
                        Text("Change Password")
                    }
                    
                    Button {
                        // theme color change
                    } label: {
                        Text("Change Theme")
                    }
                    
                    Button {
                        // delete account
                    } label: {
                        Text("Delete Account")
                            .foregroundColor(.red)
                    }

                }
                .listStyle(.plain)
                
                Spacer()
            }
            .onChange(of: selectedItem, perform: { newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            })
            .fullScreenCover(isPresented: $showFullScreen, content: {
                if let selectedImage {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .ignoresSafeArea()
                    }
                    .interactiveDismissDisabled(false)
                }
            })
            .navigationTitle("Profile")
        }
    }
}

struct SearchResultsView: View {
    let tracks: [Track]
    @ObservedObject var vm: MusicViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Search Results (\(tracks.count))")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(tracks, id: \.id) { track in
                        SearchResultRow(track: track, vm: vm)
                    }
                }
            }
            .frame(maxHeight: 400)
        }
    }
}

struct SearchResultRow: View {
    let track: Track
    @ObservedObject var vm: MusicViewModel
    
    var body: some View {
        Button(action: {
            vm.selectTrack(track)
        }) {
            HStack(spacing: 12) {
                // Album art
                AsyncImage(url: URL(string: track.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Track info
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(track.artist_name)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Duration
                Text(vm.formatDuration(track.duration))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                // Play button
                Button(action: {
                    if let url = URL(string: track.audio) {
                        vm.selectTrack(track)
                        vm.playSong(url: url)
                    }
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .background(Color.white.opacity(0.1))
            .padding(.leading, 82)
    }
}

#Preview {
    ContentView()
}
