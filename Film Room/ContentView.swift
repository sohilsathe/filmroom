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
    @State private var downloadInProgress: Bool = false
    @State private var downloadComplete: Bool = false
    @State private var videoURL: URL? = nil
    
    let destinationPath = getVideosDirectory()?.path() ?? "~/Downloads/"
    
    var body: some View {
        VStack {
            if downloadComplete, let videoURL = videoURL {
                // Show video player if the video is downloaded
                PlayerView(videoURL: videoURL)
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
                
            } else {
                // Default view with title, text field, and button
                VStack {
                    Text("Film Room")
                        .font(.system(size: 64))  // Make the font size larger
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    HStack {
                        TextField("YouTube link", text: $youtubeLink)
                            .padding()
                            .font(.system(size: 32))  // Make the font size larger
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .background(.black)
                            .padding(.horizontal, 20)
                        
                        Button(action: {
                            //TODO: refactor out
                            downloadInProgress = true
                            DispatchQueue.global().async {
                                downloadYoutubeVideo(url: youtubeLink, destinationPath: destinationPath, videoName: VIDEO_NAME) { success, msg in
                                    if success {
                                        DispatchQueue.main.async {
                                            videoURL = URL(fileURLWithPath: destinationPath).appendingPathComponent("\(VIDEO_NAME).\(VIDEO_EXT)")
                                            downloadInProgress = false
                                            downloadComplete = true
                                            print ("download successful to \(destinationPath) with message \(msg ?? "no msg")")
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            print("download unsuccessful with msg \(msg ?? "no msg")")
                                            downloadInProgress = false
                                        }
                                    }
                                }
                            }
                        }) {
                            if downloadInProgress {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .green))
                                    .frame(width: 100, height: 100)
                            } else {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 100, height: 100)
                            }

                        }
                        .buttonStyle(PlainButtonStyle())
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

//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
