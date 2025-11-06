/*
 * File: CoinsCompactSelector.swift
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

struct CoinsCompactSelector: View {
    @Binding var csv: String           // terhubung ke workingCoinIDsCSV di Settings
    let vs: String
    let maxPick = 30

    @State private var allEntries: [BubbleIndexEntry] = []
    @State private var allowedSymbols: Set<String> = []      // e.g. "btc"
    @State private var idToSymbol: [String:String] = [:]     // "bitcoin" -> "btc"
    @State private var selected: [String] = []               // lowercase symbols
    @State private var query: String = ""
    
    private let rowHeight: CGFloat = 24
    private let rowsVisible: Int = 4

    // Grid 4 kolom untuk chip selected
    private let columns = Array(repeating: GridItem(.flexible(minimum: 40), spacing: 4), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Input Section
            HStack(spacing: 8) {
                TextField("Coin's Ticker (e.g. btc)", text: $query) // Teks placeholder
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .onSubmit { addFromQuery() }

                Button("Add") { addFromQuery() }
                    .keyboardShortcut(.return, modifiers: [])
            }
            .padding(8)

            Divider()

            // MARK: - Selected Grid Section
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
                    ForEach(selected, id: \.self) { sym in
                        Chip(symbol: sym.uppercased()) {
                            removeCoin(sym)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .frame(height: CGFloat(rowsVisible) * rowHeight)
            .padding(.horizontal, 4)

            Divider()

            // MARK: - Footer Section
            HStack {
                Text("\(selected.count)/\(maxPick) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    clearAll()
                } label: { Image(systemName: "xmark.circle.fill") }
                .buttonStyle(.plain)
                .help("Clear all")
            }
            .padding(8)
        }
        .onAppear { bootstrap() }
    }

    // MARK: - Bootstrapping
    private func bootstrap() {
        selected = csv.split(separator: ",").map { String($0).lowercased() }

        // cache dulu
        let disk = BubbleIndex.loadFromDisk()
        if !disk.isEmpty { apply(entries: disk) }

        // optional refresh (satu request, cached 1 jam)
        Task {
            if let fresh = try? await BubbleIndex.shared.load(vs: vs) {
                await MainActor.run { apply(entries: fresh) }
            }
        }
    }

    private func apply(entries: [BubbleIndexEntry]) {
        allEntries = entries
        allowedSymbols = Set(entries.map { $0.symbol })
        idToSymbol = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0.symbol) })
        selected = selected.filter { allowedSymbols.contains($0) }
        csv = selected.joined(separator: ",")
    }

    // MARK: - Actions
    private func addFromQuery() {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        // terima symbol langsung, atau cg_id -> symbol
        let sym = allowedSymbols.contains(q) ? q : (idToSymbol[q] ?? "")
        if !sym.isEmpty {
            addCoin(sym)
            query = "" // sukses -> bersihkan field
        } else {
            // tidak valid -> bersihkan (indikasi tidak tersedia)
            query = ""
        }
    }

    private func addCoin(_ sym: String) {
        guard allowedSymbols.contains(sym),
              !selected.contains(sym),
              selected.count < maxPick else { return }
        selected.append(sym)
        csv = selected.joined(separator: ",")
    }

    private func removeCoin(_ sym: String) {
        selected.removeAll { $0 == sym }
        csv = selected.joined(separator: ",")
    }

    private func clearAll() {
        selected.removeAll()
        csv = ""
    }
}

// MARK: - Chip View
private struct Chip: View {
    let symbol: String
    var onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(symbol)
                .font(.caption2.monospaced())
                .frame(maxWidth: .infinity, minHeight: 20)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.18))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.35), lineWidth: 0.5)
                )

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .offset(x: 4, y: -4)
        }
        .frame(height: 20)
    }
}
