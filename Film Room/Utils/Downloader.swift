//
//  Downloader.swift
//  Film Room
//
//  Created by Sohil Sathe on 11/8/24.
//

import Foundation

//TODO: embed directly into app https://developer.apple.com/documentation/xcode/embedding-a-helper-tool-in-a-sandboxed-app#Create-the-app-project
let DL_X_PATH = "/usr/local/bin/yt-dlp"

func downloadYoutubeVideo(url: String, destinationPath: String, videoName: String, completion: @escaping (Bool, String?) -> Void) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: DL_X_PATH)
    
    process.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
    
    process.arguments = [
        url,
        "-f", "bestvideo[vcodec^=avc1]+bestaudio[acodec^=mp4a]/mp4",
        "-o", "\(destinationPath)/\(videoName)",
        "--force-overwrites"
    ]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    do {
        try process.run()
    } catch {
        completion(false, "Failed to start yt-dlp: \(error.localizedDescription)")
        return
    }
    
    process.terminationHandler = { _ in
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        if process.terminationStatus == 0 {
            completion(true, output)
        } else {
            completion(false, "yt-dlp failed: \(output)")
        }
    }
}
