/*
 * File: Models.swift
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

struct PriceItem: Identifiable, Hashable {
    let id: String          // cg_id
    let symbol: String      // e.g. "BTC"
    let value: Double       // price in selected fiat
    let changeDay: Double?  // 24h change for coloring
    let logoURL: URL?       // https://cryptobubbles.net/backend/data/logos/1.png
    let cbNumId: Int?       // <— numeric id dari path logo "data/logos/{id}.png"
}
