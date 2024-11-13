import SwiftUI
import AVKit
import SwiftData

// config for yt-dlp
let VIDEO_NAME = "content"
let VIDEO_EXT = "mp4"

// [refresh (seek) rate in seconds, step size in seconds]
let REWIND_FAST = [0.15, -0.50]
let REWIND_NORMAL = [0.15, -0.1]
let REWIND_SLOW = [0.15, -0.05]
let FF_FAST = [0.2, 1.0]
let FF_NORMAL = [0.2, 0.2]
let FF_SLOW = [0.2, 0.1]

struct AVPlayerLayerRepresentable: NSViewRepresentable {
    let videoURL: URL
    private let player = AVPlayer()
    
    @Binding var isRewinding: Bool
    @Binding var isPaused: Bool
    
    // rewind / fast forward related
    @Binding var refreshRate: Double
    @Binding var stepSize: Double
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        player.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
        
        view.layer = CALayer()
        view.layer?.addSublayer(playerLayer)
        
        playerLayer.frame = view.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        // Register key event handlers
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp]) { event in
            return context.coordinator.handleKeyEvent(event)
        }
        
        context.coordinator.setupPlayerObservers()
        player.play()
        
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let playerLayer = nsView.layer?.sublayers?.first as? AVPlayerLayer {
            playerLayer.frame = nsView.bounds
        }
        
        if isPaused {
            player.pause()
        } else if !isRewinding {
            player.play()
        }
        
        if isRewinding {
            context.coordinator.startRewind(refreshRate: refreshRate, stepSize: stepSize)
        } else {
            context.coordinator.stopRewind()
        }
    }

    class Coordinator: NSObject {
        let parent: AVPlayerLayerRepresentable
        private var rewindTimer: Timer?
        
        init(_ parent: AVPlayerLayerRepresentable) {
            self.parent = parent
        }
        
        func setupPlayerObservers() {
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                   object: nil,
                                                   queue: .main) { _ in
                self.parent.player.seek(to: .zero)
            }
        }

        func startRewind(refreshRate: Double, stepSize: Double) {
            guard rewindTimer == nil else { return }
            rewindTimer = Timer.scheduledTimer(withTimeInterval: refreshRate, repeats: true) { _ in
                let currentTime = self.parent.player.currentTime()
                let rewindTime = CMTime(seconds: max(currentTime.seconds + stepSize, 0), preferredTimescale: currentTime.timescale)
                self.parent.player.seek(to: rewindTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }

        func stopRewind() {
            rewindTimer?.invalidate()
            rewindTimer = nil
        }

        func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
            switch event.keyCode {
            case 32: // u
                handleKeyEventHelper(event, refreshRate: REWIND_FAST[0], stepSize: REWIND_FAST[1])
                return nil
            case 34: // i
                handleKeyEventHelper(event, refreshRate: FF_FAST[0], stepSize: FF_FAST[1])
                return nil
            case 38: // j
                handleKeyEventHelper(event, refreshRate: REWIND_NORMAL[0], stepSize: REWIND_NORMAL[1])
                return nil
            case 40: // k
                handleKeyEventHelper(event, refreshRate: FF_NORMAL[0], stepSize: FF_NORMAL[1])
                return nil
            case 45: // n
                handleKeyEventHelper(event, refreshRate: REWIND_SLOW[0], stepSize: REWIND_SLOW[1])
                return nil
            case 46: // m
                handleKeyEventHelper(event, refreshRate: FF_SLOW[0], stepSize: FF_SLOW[1])
                return nil
            case 49: // space bar
                if event.type == .keyDown {
                    parent.isPaused.toggle()
                }
                return nil
            default:
                return event
            }
        }
        
        func handleKeyEventHelper(_ event: NSEvent, refreshRate: Double, stepSize: Double) {
            if event.type == .keyDown {
                parent.isPaused = true
                parent.refreshRate = refreshRate
                parent.stepSize = stepSize
                parent.isRewinding = true
            } else if event.type == .keyUp {
                parent.isRewinding = false
                parent.refreshRate = 0.0
                parent.stepSize = 0.0
                parent.isPaused = false
            }
        }
    }
}

struct PlayerView: View {
    let videoURL: URL
    @State private var isRewinding = false
    @State private var isPaused = false
    @State private var refreshRate = 0.0
    @State private var stepSize = 0.0
    
    var body: some View {
        VStack {
            AVPlayerLayerRepresentable(videoURL: videoURL, isRewinding: $isRewinding, isPaused: $isPaused, refreshRate: $refreshRate, stepSize: $stepSize)
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
        }
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
                // video player view
                VStack {
                    PlayerView(videoURL: videoURL).edgesIgnoringSafeArea(.all)
                    BottomBarView().padding(.bottom, 20)
                }
                .background(Color.black)
            } else {
                // home view
                VStack {
                    Text("Film Room")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                        .padding(.top, 50)

                    HStack {
                        TextField("YouTube link", text: $youtubeLink)
                            .padding(.vertical, 10)
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .background(Color.clear)
                            .accentColor(.white)  // white cursor
                            .padding(.horizontal, 20)
                            .textFieldStyle(PlainTextFieldStyle())
                            .disableAutocorrection(true)

                        Button(action: {
                            downloadInProgress = true
                            DispatchQueue.global().async {
                                downloadYoutubeVideo(url: youtubeLink, destinationPath: destinationPath, videoName: VIDEO_NAME) { success, msg in
                                    if success {
                                        DispatchQueue.main.async {
                                            videoURL = URL(fileURLWithPath: destinationPath).appendingPathComponent("\(VIDEO_NAME).\(VIDEO_EXT)")
                                            downloadInProgress = false
                                            downloadComplete = true
                                        }
                                    } else {
                                        DispatchQueue.main.async {
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
                                Image(systemName: "play.square.fill")
                                    .resizable()
                                    .foregroundColor(.red)
                                    .frame(width: 100, height: 100)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
            }
        }
        .preferredColorScheme(.dark)
    }
}


struct BottomBarView: View {
    var body: some View {
        HStack(spacing: 50) {
            VStack(spacing: 10) {
                Label("Fast Rewind", systemImage: "u.square")
                Label("Normal Rewind", systemImage: "j.square")
                Label("Slow Rewind", systemImage: "n.square")
            }
            .foregroundColor(.white)
            
            VStack(spacing: 10) {
                Label("Fast Forward", systemImage: "i.square")
                Label("Normal Forward", systemImage: "k.square")
                Label("Slow Forward", systemImage: "m.square")
            }
            .foregroundColor(.white)
            
            VStack(spacing: 10) {
                Label("Play/Pause", systemImage: "space")
                Text("Space Bar")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .foregroundColor(.white)
        }
        .padding()
    }
}

//#Preview {
//    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
//}
