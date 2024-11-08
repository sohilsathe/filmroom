//
//  FileSystem.swift
//  Film Room
//
//  Created by Sohil Sathe on 11/8/24.
//

import Foundation

func getVideosDirectory() -> URL? {
    let fileManager = FileManager.default
    if let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        let appDirectory = appSupportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier ?? "Film Room")

        if !fileManager.fileExists(atPath: appDirectory.path()) {
            do {
                try fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create application directory: \(error.localizedDescription)")
                return nil
            }
        }

        let videosDirectory = appDirectory.appendingPathComponent("Videos")
        if !fileManager.fileExists(atPath: videosDirectory.path()) {
            do {
                try fileManager.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create videos directory: \(error.localizedDescription)")
                return nil
            }
        }

        return videosDirectory
    }

    return nil
}
