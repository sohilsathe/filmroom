//
//  ContentView.swift
//  Film Room
//
//  Created by Sohil Sathe on 11/8/24.
//

import SwiftUI
import AVKit

import SwiftData

let TEST_VIDEO_FP = "/Users/sohil/Downloads/steph/cash.mp4"

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

    var body: some View {
        VStack {
            Text("Film Room")
                .font(.largeTitle)
                .padding()
            
            
            AVPlayerViewRepresentable(videoURL: URL(fileURLWithPath: TEST_VIDEO_FP))
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
