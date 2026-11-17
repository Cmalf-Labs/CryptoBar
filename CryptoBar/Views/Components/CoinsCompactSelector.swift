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
import UniformTypeIdentifiers

struct CoinsCompactSelector: View {
    @Binding var csv: String           // terhubung ke workingCoinIDsCSV di Settings
    let vs: String
    let maxPick = 100

    @State private var allEntries: [BubbleIndexEntry] = []
    @State private var allowedSymbols: Set<String> = []      // e.g. "btc"
    @State private var idToSymbol: [String:String] = [:]     // "bitcoin" -> "btc"
    @State private var selected: [String] = []               // lowercase symbols
    @State private var query: String = ""
    @FocusState private var fieldFocused: Bool
    @State private var alreadyAddedNotice: String? = nil   // toast "X is already added"
    @State private var draggedSymbol: String? = nil        // drag & drop reorder chip
    
    private let rowHeight: CGFloat = 24
    private let rowsVisible: Int = 4

    // Grid 4 kolom untuk chip selected
    private let columns = Array(repeating: GridItem(.flexible(minimum: 40), spacing: 4), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Input Section (dengan suggestion/detection)
            ZStack(alignment: .topLeading) {
                HStack(spacing: 8) {
                    TextField("Coin's Ticker or name (e.g. sol)", text: $query) // Teks placeholder
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .focused($fieldFocused)
                        .onSubmit { addTopSuggestionOrQuery() }

                    Button("Add") { addTopSuggestionOrQuery() }
                        .keyboardShortcut(.return, modifiers: [])
                }
                .padding(8)

                // Dropdown suggestion: muncul saat mengetik, klik untuk menambah
                if fieldFocused && !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(suggestions) { entry in
                            Button {
                                if selected.contains(entry.symbol) {
                                    showAlreadyAdded(entry.symbol)
                                } else {
                                    addCoin(entry.symbol)
                                    query = ""
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(entry.symbol.uppercased())
                                        .font(.caption.monospaced().bold())
                                    Text(entry.id)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    if selected.contains(entry.symbol) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                    }
                                }
                                .padding(.vertical, 5)
                                .padding(.horizontal, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                    .padding(.horizontal, 8)
                    .offset(y: 38)
                    .zIndex(1)
                }

                // Toast "already added" saat koin yang sudah dipilih diklik
                if let notice = alreadyAddedNotice {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                        Text("\(notice) is already added")
                    }
                    .font(.caption)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
                    .padding(.horizontal, 8)
                    .offset(y: 38)
                    .zIndex(2)
                }
            }
            .zIndex(1)

            Divider()

            // MARK: - Selected Grid Section
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
                    ForEach(selected, id: \.self) { sym in
                        Chip(symbol: sym.uppercased()) {
                            removeCoin(sym)
                        }
                        // Drag & drop untuk urut ulang: chip pertama tampil di menu bar
                        .onDrag {
                            draggedSymbol = sym
                            return NSItemProvider(object: sym as NSString)
                        }
                        .onDrop(of: [.text], delegate: ChipDropDelegate(
                            item: sym,
                            items: $selected,
                            draggedItem: $draggedSymbol,
                            onReorder: { csv = selected.joined(separator: ",") }
                        ))
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
        // Defensif: kalau feed masih berisi cg_id dobel, ambil simbol pertama
        // (uniqueKeysWithValues akan fatalError dan nge-crash app).
        idToSymbol = Dictionary(entries.map { ($0.id, $0.symbol) }, uniquingKeysWith: { first, _ in first })
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

    // MARK: - Suggestions (detection saat mengetik)
    // Cocokkan symbol atau cg_id; yang diawali query didahulukan, lalu yang mengandung.
    // Urutan feed = urutan rank, jadi suggestion teratas = rank tertinggi.
    // Koin yang sudah dipilih tetap tampil (checkmark hijau); diklik menampilkan toast "already added".
    private var suggestions: [BubbleIndexEntry] {
        let q = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        let prefix = allEntries.filter { $0.symbol.hasPrefix(q) || $0.id.hasPrefix(q) }
        let contains = allEntries.filter {
            !$0.symbol.hasPrefix(q) && !$0.id.hasPrefix(q)
            && ($0.symbol.contains(q) || $0.id.contains(q))
        }
        return Array((prefix + contains).prefix(6))
    }

    // Enter / tombol Add: pakai suggestion teratas yang BELUM dipilih kalau ada,
    // kalau tidak pakai query apa adanya
    private func addTopSuggestionOrQuery() {
        if let top = suggestions.first(where: { !selected.contains($0.symbol) }) {
            addCoin(top.symbol)
            query = ""
        } else {
            addFromQuery()
        }
    }

    // Koin sudah dipilih tapi diklik di suggestion: tampilkan toast 2 detik
    private func showAlreadyAdded(_ sym: String) {
        let label = sym.uppercased()
        alreadyAddedNotice = label
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                if alreadyAddedNotice == label { alreadyAddedNotice = nil }
            }
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

// MARK: - Drag & drop reorder untuk chip
// DropDelegate standar: saat chip yang didrag melewati chip lain, pindahkan langsung.
private struct ChipDropDelegate: DropDelegate {
    let item: String
    @Binding var items: [String]
    @Binding var draggedItem: String?
    var onReorder: () -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem,
              draggedItem != item,
              let from = items.firstIndex(of: draggedItem),
              let to = items.firstIndex(of: item) else { return }
        withAnimation(.default) {
            items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            onReorder()
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
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
