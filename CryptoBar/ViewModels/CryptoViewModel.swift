/*
 * File: CryptoViewModel.swift
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

import SwiftUI
import Combine

@MainActor
final class CryptoViewModel: ObservableObject {
    // User mengetik symbol atau cg_id di sini, pemetaan dilakukan otomatis
    @AppStorage("coinIDsCSV") var coinIDsCSV: String = "btc,eth,xrp,bnb,sol,doge,tron,ada"
    @AppStorage("vs") var vs: String = "usd"
    @AppStorage("interval") var interval: Int = 30

    // Fiat yang didukung (mengikuti daftar di CryptoBubbles Settings)
    let supportedFiat: [String] = ["usd","eur","gbp","brl","cad","aud","pln","inr","rub","chf","zar","try","jpy","krw"]

    @Published var items: [PriceItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var refreshTask: Task<Void, Never>?
    private var allCache: [BubbleItem] = []
    private var symbolToId: [String:String] = [:]  // "BTC" -> "bitcoin"

    func start(barTitle: BarTitle) {
        refreshTask?.cancel()
        barTitle.text = "Loading…"                    // cegah stuck
        refreshTask = Task { [weak self] in
            guard let self else { return }
            // Refresh sekali segera
            await self.refresh(barTitle: barTitle)
            // Delay awal 5 detik untuk default data setelah app jalan
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            // Loop normal
            while !Task.isCancelled {
                await self.refresh(barTitle: barTitle)
                try? await Task.sleep(nanoseconds: UInt64(self.interval) * 1_000_000_000)
            }
        }
    }


    func stop() { refreshTask?.cancel() }

    private func buildSymbolMap(from all: [BubbleItem]) {
        var map: [String:String] = [:]
        for e in all {
            map[e.symbol.uppercased()] = e.cg_id
        }
        self.symbolToId = map
    }

    private func resolveCgIDs(from input: String) -> [String] {
        let tokens = input.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var result: [String] = []
        for t in tokens {
            let u = t.uppercased()
            if let id = symbolToId[u] {
                result.append(id)
            } else {
                // fallback: dianggap sudah cg_id
                result.append(t.lowercased())
            }
        }
        // Batasi maksimal 30 coin
        return Array(result.prefix(30))
    }

    func refresh(barTitle: BarTitle) async {
        isLoading = true
        defer { isLoading = false }
        do {
            // Ambil semua data untuk fiat terpilih (atau USD fallback di service)
            let all = try await BubblesService.fetchAll(vs: vs)
            self.allCache = all
            buildSymbolMap(from: all)

            // Petakan input (symbol atau cg_id) -> cg_id final
            let resolved = resolveCgIDs(from: coinIDsCSV)

            // Filter sesuai cg_id dan pertahankan urutan input
            let filtered: [BubbleItem] = resolved.compactMap { id in
                all.first { $0.cg_id.lowercased() == id.lowercased() }
            }

            // Map ke PriceItem untuk UI
            self.items = filtered.map { e in
                PriceItem(
                    id: e.cg_id,
                    symbol: e.symbol,
                    value: e.price,
                    changeDay: e.performance?.day,
                    logoURL: BubblesService.logoURL(from: e.image),
                    cbNumId: extractCBNumId(from: e.image) // <— isi otomatis
                )
            }

            // Label menubar: pakai symbol, mis. "BTC-USD $110,497"
            if let first = items.first {
                let code = vs.uppercased()
                let nf = NumberFormatter()
                nf.numberStyle = .currency
                nf.currencyCode = code
                let priceText = formatCurrency(first.value, vs: vs)
                barTitle.text = "\(first.symbol.uppercased())-\(code) \(priceText)"
            } else {
                barTitle.text = "CMALF-CryptoBar"
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func formatCurrency(_ v: Double, vs: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = vs.uppercased()

        // Presisi adaptif untuk koin murah
        if v >= 1 {
            f.maximumFractionDigits = 2
            f.minimumFractionDigits = 2
        } else if v >= 0.01 {
            f.maximumFractionDigits = 4
            f.minimumFractionDigits = 2
        } else {
            f.maximumFractionDigits = 6
            f.minimumFractionDigits = 2
        }

        // Beberapa fiat seperti usd bisa tanpa desimal; override jika ingin paksa 0 desimal:
        if vs.lowercased() == "usd" && v >= 1 {
            f.maximumFractionDigits = 0
            f.minimumFractionDigits = 0
        }

        return f.string(from: NSNumber(value: v)) ?? "\(v) \(vs.uppercased())"
    }
    
    // MARK: Charts

    private func extractCBNumId(from imagePath: String) -> Int? {
        // contoh "data/logos/1.png" -> 1
        let last = (imagePath as NSString).lastPathComponent // "1.png"
        let noExt = (last as NSString).deletingPathExtension  // "1"
        return Int(noExt)
    }

    func cbNumericId(for cgID: String) -> Int? {
        // gunakan cache semua entri agar tetap sinkron dengan feed harga
        if let e = allCache.first(where: { $0.cg_id.lowercased() == cgID.lowercased() }) {
            return extractCBNumId(from: e.image)
        }
        return nil
    }

}

