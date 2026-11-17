/*
 * File: CategoryStore.swift
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Copyright (C) 2025 Cmalf-Labs
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
import Combine

// MARK: - Model (metadata.json dari cryptobubbles.net)

/// Satu entri koin di metadata.json.
/// `cg` = CoinGecko id, sama dengan cg_id di feed harga.
struct CoinMetadata: Decodable {
    let cg: String
    let fetched: Int
    let categories: [String]?
}

struct CategoryMetadataFile: Decodable {
    let updated: TimeInterval
    let coins: [String: CoinMetadata]
}

// MARK: - Store

/// Kategori koin dari cryptobubbles (`backend/data/metadata.json`, ~823 KB).
/// File-nya besar, jadi TIDAK ikut refresh harga 30 detik: diunduh sekali
/// saja saat tab Categories pertama dibuka, lalu di-cache di disk dan
/// di-refresh otomatis paling banter sekali sehari. Tombol Refresh data
/// di tab Categories memaksa unduh ulang kapan pun.
@MainActor
final class CategoryStore: ObservableObject {
    /// 12 kategori kurasi (nama persis seperti di metadata.json).
    static let curatedCategories = [
        "Layer 1 (L1)",
        "Decentralized Finance (DeFi)",
        "Meme",
        "Artificial Intelligence (AI)",
        "Real World Assets (RWA)",
        "Gaming (GameFi)",
        "Smart Contract Platform",
        "Stablecoins",
        "Tokenized Assets",
        "DePIN",
        "NFT",
        "Infrastructure"
    ]

    /// cg_id (lowercase) -> daftar kategori koin itu.
    @Published private(set) var categoriesByCoin: [String: [String]] = [:]
    /// Kapan data kategori terakhir diperbarui (dari server).
    @Published private(set) var updated: Date?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private static let cacheFileName = "category_metadata.json"
    /// Refresh otomatis paling banter sekali sehari.
    private static let maxCacheAge: TimeInterval = 24 * 3600

    var isLoaded: Bool { !categoriesByCoin.isEmpty }

    // MARK: - Load

    /// Muat dari cache disk kalau masih segar (< 24 jam), kalau tidak unduh.
    /// `force: true` = unduh ulang apa pun umur cache-nya (tombol Refresh data).
    func loadIfNeeded(force: Bool = false) async {
        if isLoading { return }
        if isLoaded && !force { return }
        // Cache disk yang masih segar — tanpa unduhan
        if !force, let cached = Self.loadFromDiskIfFresh() {
            categoriesByCoin = cached.mapping
            updated = cached.updated
            errorMessage = nil
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let url = URL(string: "https://cryptobubbles.net/backend/data/metadata.json")!
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw NSError(domain: "Network", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "HTTP error"])
            }
            let decoded = try JSONDecoder().decode(CategoryMetadataFile.self, from: data)
            Self.persist(data)
            categoriesByCoin = Self.mapping(from: decoded)
            updated = Date(timeIntervalSince1970: decoded.updated)
            errorMessage = nil
        } catch {
            // Gagal unduh: pakai cache lama kalau ada, kalau tidak tampilkan error
            if let stale = Self.loadFromDiskStale() {
                categoriesByCoin = stale.mapping
                updated = stale.updated
                errorMessage = "Couldn't refresh category data — showing cached data."
            } else if categoriesByCoin.isEmpty {
                errorMessage = "Couldn't load category data. Try again."
            }
        }
    }

    // MARK: - Query

    /// Koin-koin di sebuah kategori, urutan rank tetap (allItems sudah urut rank).
    func coins(for category: String, from allItems: [PriceItem]) -> [PriceItem] {
        allItems.filter { categoriesByCoin[$0.id.lowercased()]?.contains(category) == true }
    }

    func count(for category: String, from allItems: [PriceItem]) -> Int {
        coins(for: category, from: allItems).count
    }

    // MARK: - Cache (disk, pola yang sama dengan BubbleIndex)

    private static func supportURL() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("CryptoBar", isDirectory: true)
    }

    private static func cacheFileURL() throws -> URL {
        try supportURL().appendingPathComponent(cacheFileName)
    }

    private static func mapping(from file: CategoryMetadataFile) -> [String: [String]] {
        var out: [String: [String]] = [:]
        out.reserveCapacity(file.coins.count)
        for coin in file.coins.values {
            out[coin.cg.lowercased()] = coin.categories ?? []
        }
        return out
    }

    private static func decode(_ data: Data) -> (mapping: [String: [String]], updated: Date)? {
        guard let decoded = try? JSONDecoder().decode(CategoryMetadataFile.self, from: data) else { return nil }
        return (mapping(from: decoded), Date(timeIntervalSince1970: decoded.updated))
    }

    /// Cache disk yang masih segar (< 24 jam).
    private static func loadFromDiskIfFresh() -> (mapping: [String: [String]], updated: Date)? {
        guard let file = try? cacheFileURL(),
              let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
              let mtime = attrs[.modificationDate] as? Date,
              Date().timeIntervalSince(mtime) < maxCacheAge,
              let data = try? Data(contentsOf: file)
        else { return nil }
        return decode(data)
    }

    /// Cache disk apa pun umurnya (fallback kalau unduhan gagal).
    private static func loadFromDiskStale() -> (mapping: [String: [String]], updated: Date)? {
        guard let file = try? cacheFileURL(),
              let data = try? Data(contentsOf: file)
        else { return nil }
        return decode(data)
    }

    private static func persist(_ data: Data) {
        guard let file = try? cacheFileURL() else { return }
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
    }
}
