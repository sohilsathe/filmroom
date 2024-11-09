//
//  ContentView.swift
//  Film Room
//
//  Created by Sohil Sathe on 11/8/24.
//

import SwiftUI
import AVKit

import SwiftData

//TODO: Replace print with logging

let VIDEO_NAME = "content"
let VIDEO_EXT = "mp4"

struct AVPlayerViewRepresentable: NSViewRepresentable {
    let videoURL: URL

    func makeNSView(context: Context) -> AVPlayerView {
        // Create the player view
        let playerView = AVPlayerView()
        let player = AVPlayer(url: videoURL)
        playerView.player = player
        
        // start playback automatically
        // player.play()
        
        return playerView
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        // Implement any updates if needed
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    @State private var youtubeLink: String = ""
    @State private var isVideoDownloaded: Bool = false
    @State private var videoURL: URL? = nil
    
    let destinationPath = getVideosDirectory()?.path() ?? "~/Downloads/"
    
    var body: some View {
        VStack {
            if isVideoDownloaded, let videoURL = videoURL {
                // Show video player if the video is downloaded
                PlayerView(videoURL: videoURL)
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
                
            } else {
                // Default view with title, text field, and button
                VStack {
                    Text("Film Room")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    HStack {
                        TextField("YouTube link", text: $youtubeLink)
                            .padding()
                            .cornerRadius(8)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        Button(action: {
                            downloadYoutubeVideo(url: youtubeLink, destinationPath: destinationPath, videoName: VIDEO_NAME) { success, msg in
                                if success {
                                    self.videoURL = URL(fileURLWithPath: destinationPath).appendingPathComponent("\(VIDEO_NAME).\(VIDEO_EXT)")
                                    self.isVideoDownloaded = true
                                    print ("download successful to \(destinationPath) with message \(msg ?? "no msg")")
                                } else {
                                    print("download unsuccessful with msg \(msg ?? "no msg")")
                                }
                                
                            }
                        }) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 50, height: 50)
                                
                        }
                        .padding(.trailing, 20)
                        
                    }
                    .padding(.top, 20)
                    .background(Color.black)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

struct PlayerView: View {
    let videoURL: URL

    var body: some View {
        AVPlayerViewRepresentable(videoURL: videoURL)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
