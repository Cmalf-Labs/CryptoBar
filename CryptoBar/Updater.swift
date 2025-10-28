/*
 * File: Updater.swift
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2025 CMALF
 *
 * This file is part of CryptoBar.
 *
 * CryptoBar is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * CryptoBar is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

import Foundation
import AppKit

struct GHRelease: Decodable, Sendable {
    let tag_name: String
    let html_url: String
    let assets: [Asset]

    struct Asset: Decodable, Sendable {
        let name: String
        let browser_download_url: String
    }
}

final class UpdateManager: NSObject, URLSessionDownloadDelegate {
    static let shared = UpdateManager()
    private var progressHandler: ((Double)->Void)?

    func fetchLatestRelease(owner: String, repo: String) async throws -> GHRelease {
        var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")!)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("CryptoBar-Updater", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: req)
        let rel: GHRelease = try await MainActor.run {
            try JSONDecoder().decode(GHRelease.self, from: data)
        }
        return rel
    }

    func pickDMG(from r: GHRelease) -> URL? {
        r.assets.first { $0.name.hasSuffix(".dmg") }.flatMap { URL(string: $0.browser_download_url) }
    }

    // Download with progress
    func downloadDMG(from url: URL, onProgress: @escaping (Double)->Void) async throws -> URL {
        progressHandler = onProgress
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let (tmpURL, _) = try await session.download(from: url)
        let dest = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(url.lastPathComponent)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tmpURL, to: dest)
        return dest
    }

    // URLSessionDownloadDelegate
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // no-op
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        progressHandler?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))
    }

    @discardableResult
    func installDMG(at dmgURL: URL) throws -> URL {
        let mountPoint = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("CryptoBarMount-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)
        try run("/usr/bin/hdiutil", ["attach", dmgURL.path, "-nobrowse", "-quiet", "-mountpoint", mountPoint.path])

        let appInDMG = mountPoint.appendingPathComponent("CryptoBar.app")
        let dest = URL(fileURLWithPath: "/Applications/CryptoBar.app")
        try? FileManager.default.removeItem(at: dest)
        try run("/usr/bin/ditto", ["-rsrc", appInDMG.path, dest.path])
        _ = try? run("/usr/bin/xattr", ["-dr", "com.apple.quarantine", dest.path])

        try run("/usr/bin/hdiutil", ["detach", mountPoint.path, "-quiet"])
        return dest
    }

    func relaunch(from installedAppURL: URL) {
        NSWorkspace.shared.openApplication(at: installedAppURL, configuration: .init(), completionHandler: nil)
        NSApp.terminate(nil)
    }

    @discardableResult
    private func run(_ tool: String, _ args: [String]) throws -> Int32 {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: tool)
        p.arguments = args
        try p.run()
        p.waitUntilExit()
        if p.terminationStatus != 0 {
            throw NSError(domain: "Updater", code: Int(p.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "\(tool) failed"])
        }
        return p.terminationStatus
    }
}
