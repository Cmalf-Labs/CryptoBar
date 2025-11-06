/*
 * File: ChartModels.swift
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

enum ChartRange: String, CaseIterable, Identifiable {
    case hour, day, week, month, year
    var id: String { rawValue }
    var title: String {
        switch self {
        case .hour:  return "Hour"
        case .day:   return "Day"
        case .week:  return "Week"
        case .month: return "Month"
        case .year:  return "Year"
        }
    }
    var path: String {
        switch self {
        case .hour:  return "hour"
        case .day:   return "day"
        case .week:  return "week"
        case .month: return "month"
        case .year:  return "year"
        }
    }
}

struct ChartPoint: Codable, Identifiable {
    let t: TimeInterval
    let p: Double
    var id: TimeInterval { t }
    var date: Date { Date(timeIntervalSince1970: t) }
}

struct BubbleMetrics: Decodable {
    let id: Int?
    let s: String?
    let r: Int?
    let mc: Double?
    let v: Double?
    let p: Double?

    enum CodingKeys: String, CodingKey { case id, s, r, mc, v, p }

    private struct AnyKey: CodingKey {
        var stringValue: String; init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int?; init?(intValue: Int) { self.intValue = intValue; self.stringValue = "\(intValue)" }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // id
        if let intId = try? c.decodeIfPresent(Int.self, forKey: .id) {
            self.id = intId
        } else if let strId = try? c.decodeIfPresent(String.self, forKey: .id) {
            self.id = Int(strId)
        } else { self.id = nil }

        // symbol -> s
        if let any = try? decoder.container(keyedBy: AnyKey.self),
           let key = AnyKey(stringValue: "symbol") {
            self.s = try? any.decodeIfPresent(String.self, forKey: key)
        } else {
            self.s = nil
        }

        // rank -> r, termasuk market_cap_rank
        if let ir = try? c.decodeIfPresent(Int.self, forKey: .r) {
            self.r = ir
        } else if let sr = try? c.decodeIfPresent(String.self, forKey: .r), let v = Int(sr) {
            self.r = v
        } else {
            let any = try decoder.container(keyedBy: AnyKey.self)
            self.r = (try? any.decodeIfPresent(Int.self, forKey: AnyKey(stringValue: "rank")!))
                 ?? (try? any.decodeIfPresent(Int.self, forKey: AnyKey(stringValue: "market_cap_rank")!))
        }

        // mc dari alias
        self.mc = BubbleMetrics.decodeDouble(decoder: decoder,
                                             primary: c, primaryKey: .mc,
                                             aliases: ["marketcap", "market_cap", "marketCap"])

        // v dari alias
        self.v  = BubbleMetrics.decodeDouble(decoder: decoder,
                                             primary: c, primaryKey: .v,
                                             aliases: ["volume", "total_volume", "volume24h", "volume_24h", "totalVolume"])

        // p atau price
        self.p  = BubbleMetrics.decodeDouble(decoder: decoder, primary: c, primaryKey: .p,
                                             aliases: ["price"])
    }

    private static func decodeDouble(decoder: Decoder,
                                     primary: KeyedDecodingContainer<CodingKeys>,
                                     primaryKey: CodingKeys,
                                     aliases: [String]) -> Double? {
        if let d = try? primary.decodeIfPresent(Double.self, forKey: primaryKey) { return d }
        if let s = try? primary.decodeIfPresent(String.self, forKey: primaryKey) {
            return Double(s.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: ""))
        }
        let any = try? decoder.container(keyedBy: AnyKey.self)
        for k in aliases {
            if let d = try? any?.decodeIfPresent(Double.self, forKey: AnyKey(stringValue: k)!) { return d }
            if let s = try? any?.decodeIfPresent(String.self, forKey: AnyKey(stringValue: k)!) {
                return Double(s.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: ""))
            }
        }
        return nil
    }
}
