/*
 * File: BubblesService.swift
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

enum BubblesService {
    static func fetchAll(vs: String) async throws -> [BubbleItem] {
        let vsLower = vs.lowercased()
        let candidates = [
            URL(string: "https://cryptobubbles.net/backend/data/bubbles1000.\(vsLower).json")!,
            URL(string: "https://cryptobubbles.net/backend/data/bubbles1000.usd.json")!
        ]
        var lastError: Error?
        for url in candidates {
            do {
                let (data, resp) = try await URLSession.shared.data(from: url)
                if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) { continue }
                return try JSONDecoder().decode([BubbleItem].self, from: data)
            } catch {
                lastError = error
                continue
            }
        }
        throw lastError ?? NSError(domain: "Network", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "Fetch failed"])
    }

    static func logoURL(from path: String) -> URL? {
        // CryptoBubbles memberi path relatif "data/logos/1.png"
        URL(string: "https://cryptobubbles.net/backend/\(path)")
    }
}

