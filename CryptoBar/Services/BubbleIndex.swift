/*
 * File: BubbleIndex.swift
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

struct BubbleIndexEntry: Identifiable, Hashable, Codable {
    let id: String
    let symbol: String
    var display: String { symbol.uppercased() + " — " + id }
}

actor BubbleIndex {
    static let shared = BubbleIndex()
    private var mem: [BubbleIndexEntry] = []
    private var last: Date?

    func load(vs: String) async throws -> [BubbleIndexEntry] {
        if let last, Date().timeIntervalSince(last) < 3600, !mem.isEmpty { return mem }
        let items = try await BubblesService.fetchAll(vs: vs)   // service eksisting
        var seen = Set<String>()
        let entries: [BubbleIndexEntry] = items.compactMap { it in
            let id = it.cg_id.lowercased()
            let sym = it.symbol.lowercased()
            let k = sym + "|" + id
            if seen.contains(k) { return nil }
            seen.insert(k)
            return BubbleIndexEntry(id: id, symbol: sym)
        }
        mem = entries
        last = Date()
        try Self.persist(entries)
        return entries
    }

    // MARK: - File helpers (nonisolated & static)

    private static func supportURL() throws -> URL {
        try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("CryptoBar", isDirectory: true)
    }

    private static func persist(_ entries: [BubbleIndexEntry]) throws {
        let dir = try supportURL()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("bubble_index.json")
        try JSONEncoder().encode(entries).write(to: file, options: .atomic)
    }

    // Boleh dipanggil sinkron dari UI
    nonisolated static func loadFromDisk() -> [BubbleIndexEntry] {
        guard let dir = try? supportURL() else { return [] }
        let file = dir.appendingPathComponent("bubble_index.json")
        guard let data = try? Data(contentsOf: file) else { return [] }
        return (try? JSONDecoder().decode([BubbleIndexEntry].self, from: data)) ?? []
    }
}
