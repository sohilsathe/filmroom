//
//  Downloader.swift
//  Film Room
//
//  Created by Sohil Sathe on 11/8/24.
//

import Foundation

//TODO: use which to dynamically fetch
let DL_X_PATH = "usr/local/bin/yt-dlp"

func downloadYoutubeVideo(url: String, destinationPath: String, videoName: String, completion: @escaping (Bool, String?) -> Void) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: DL_X_PATH)
    
    process.arguments = [
        url,
        "-o", "\(destinationPath)/\(videoName)"
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
