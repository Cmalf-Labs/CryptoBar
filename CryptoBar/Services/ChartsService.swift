/*
 * File: ChartsService.swift
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

enum ChartsServiceError: Error { case badURL, badStatus(Int), decode }

final class ChartsService {
    static let shared = ChartsService()
    private init() {}

    func fetchChart(coinNumId: Int, fiat: String, range: ChartRange) async throws -> [ChartPoint] {
        let urlStr = "https://cryptobubbles.net/backend/data/charts/\(range.path)/\(coinNumId)/\(fiat.uppercased()).json"
        guard let url = URL(string: urlStr) else { throw ChartsServiceError.badURL }
        let (data, resp) = try await URLSession.shared.data(from: url)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ChartsServiceError.badStatus(http.statusCode)
        }
        return try JSONDecoder().decode([ChartPoint].self, from: data)
    }

    func fetchMetrics(fiat: String, coinNumId: Int?, symbol: String? = nil) async throws -> BubbleMetrics? {
        let urlStr = "https://cryptobubbles.net/backend/data/bubbles1000.\(fiat.lowercased()).json"
        guard let url = URL(string: urlStr) else { throw ChartsServiceError.badURL }
        let (data, resp) = try await URLSession.shared.data(from: url)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ChartsServiceError.badStatus(http.statusCode)
        }
        let dec = JSONDecoder()
        dec.keyDecodingStrategy = .convertFromSnakeCase
        let list = try dec.decode([BubbleMetrics].self, from: data)
        if let id = coinNumId, let hit = list.first(where: { $0.id == id }) { return hit }
        if let s = symbol?.uppercased(),
           let hit = list.first(where: { ($0.s ?? "").uppercased() == s }) { return hit }
        return nil
    }
}
