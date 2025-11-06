/*
 * File: BubbleSearchPicker.swift
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

struct BubbleSearchPicker: View {
    @Binding var csv: String
    let vs: String
    let limit: Int = 30

    @State private var all: [BubbleIndexEntry] = []
    @State private var shown: [BubbleIndexEntry] = []
    @State private var selected: [BubbleIndexEntry] = []
    @State private var searchText = ""
    @State private var debounce: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(selected) { c in
                        HStack(spacing: 6) {
                            Text(c.symbol.uppercased())
                            Button("x") { remove(c) }.buttonStyle(.plain)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.ultraThinMaterial).cornerRadius(8)
                    }
                }
            }

            List(shown) { c in
                Button {
                    add(c)
                } label: {
                    HStack {
                        Text(c.display)
                        Spacer()
                        if selected.contains(c) { Image(systemName: "checkmark.circle.fill") }
                    }
                }
                .buttonStyle(.plain)
                .disabled(selected.contains(c) || selected.count >= limit)
            }
            .listStyle(.plain)
            .frame(minHeight: 160, maxHeight: 220)
            .searchable(text: $searchText, placement: .automatic, prompt: "Search coin (symbol or id)")

            Text("\(selected.count)/\(limit) selected")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear { bootstrap() }
        .onChange(of: searchText) { q in
            debounce?.cancel()
            debounce = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                filter(q)
            }
        }
    }

    private func bootstrap() {
        let set = Set(csv.split(separator: ",").map { String($0).lowercased() })

        let disk = BubbleIndex.loadFromDisk()           // static nonisolated
        if !disk.isEmpty {
            all = disk
            selected = disk.filter { set.contains($0.symbol) }
            shown = Array(disk.prefix(50))
        }

        // segarkan dari jaringan (1x)
        Task {
            if let fresh = try? await BubbleIndex.shared.load(vs: vs) {
                await MainActor.run {
                    all = fresh
                    let set = Set(csv.split(separator: ",").map { String($0).lowercased() })
                    selected = fresh.filter { set.contains($0.symbol) }
                    shown = Array(fresh.prefix(50))
                }
            }
        }
    }

    private func filter(_ q: String) {
        guard !all.isEmpty else { shown = []; return }
        let needle = q.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if needle.isEmpty { shown = Array(all.prefix(50)); return }
        shown = all
            .filter { $0.symbol.contains(needle) || $0.id.contains(needle) }
            .prefix(50)
            .map { $0 }
    }

    private func add(_ c: BubbleIndexEntry) {
        guard !selected.contains(c), selected.count < limit else { return }
        selected.append(c); syncCSV()
    }
    private func remove(_ c: BubbleIndexEntry) {
        selected.removeAll { $0.id == c.id && $0.symbol == c.symbol }; syncCSV()
    }
    private func syncCSV() { csv = selected.map { $0.symbol }.joined(separator: ",") }
}
