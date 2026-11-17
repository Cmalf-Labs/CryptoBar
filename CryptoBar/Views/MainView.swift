/*
 * File: MainView.swift
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
import AppKit

struct MainView: View {
    @EnvironmentObject var vm: CryptoViewModel
    @EnvironmentObject var barTitle: BarTitle
    @Environment(\.colorScheme) private var colorScheme
    @State private var pinned = false
    @State private var searchQuery = ""   // search/filter daftar harga

    @StateObject private var categoryStore = CategoryStore()
    @State private var selectedCategory: String? = nil   // kategori yang dibuka di tab Categories

    // Mode daftar: Watcher = koin pantauan (max 100), All Coins = rank 1–1200,
    // Categories = 12 kategori kurasi dari metadata cryptobubbles
    private var isAllCoins: Bool { vm.coinListMode == "all" }
    private var isCategories: Bool { vm.coinListMode == "categories" }

    // Koin-koin di kategori yang sedang dibuka (urut rank, dari allItems)
    private var categoryCoins: [PriceItem] {
        guard let cat = selectedCategory else { return [] }
        return categoryStore.coins(for: cat, from: vm.allItems)
    }

    // Daftar yang ditampilkan sesuai mode
    private var displayedItems: [PriceItem] {
        if isCategories { return categoryCoins }
        return isAllCoins ? vm.allItems : vm.items
    }

    // Daftar kategori yang sudah difilter query (level 1 tab Categories)
    private var filteredCategories: [String] {
        let q = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return CategoryStore.curatedCategories }
        return CategoryStore.curatedCategories.filter { $0.lowercased().contains(q) }
    }

    // Penghitung di samping kolom search (beda isi per mode/level)
    private var searchCountText: String {
        if isCategories && selectedCategory == nil {
            return "\(filteredCategories.count)/\(CategoryStore.curatedCategories.count)"
        }
        return "\(filteredItems.count)/\(displayedItems.count)"
    }

    // Daftar harga yang sudah difilter query (cocokkan symbol atau cg_id, urutan tetap)
    private var filteredItems: [PriceItem] {
        let q = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return displayedItems }
        return displayedItems.filter {
            $0.symbol.lowercased().contains(q) || $0.id.lowercased().contains(q)
        }
    }

    // Symbol koin pantauan (untuk status tombol Add to watcher — update instan)
    private var watcherSymbols: Set<String> {
        Set(vm.coinIDsCSV.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
    }

    // Peringkat koin di mode All Coins (allItems sudah urut rank; posisi+1 = rank, 0 = tidak ada)
    private func rank(for item: PriceItem) -> Int {
        (vm.allItems.firstIndex { $0.id.lowercased() == item.id.lowercased() } ?? -1) + 1
    }

    // Tombol Add to watcher di mode All Coins & Categories (level 2).
    // Sudah ada di pantauan -> centang hijau; pantauan penuh 100 -> mati.
    @ViewBuilder
    private func addToWatcherButton(for item: PriceItem) -> some View {
        let alreadyAdded = watcherSymbols.contains(item.symbol.lowercased())
        let full = watcherSymbols.count >= 100
        Button {
            if vm.addToWatcher(symbol: item.symbol) {
                Task { await vm.refresh(barTitle: barTitle) }
            }
        } label: {
            Image(systemName: alreadyAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(alreadyAdded ? .green : (full ? .secondary : .blue))
        }
        .buttonStyle(.plain)
        .disabled(alreadyAdded || full)
        .help(alreadyAdded ? "Already in watcher" : (full ? "Watcher is full (100)" : "Add to watcher"))
    }

    // Tombol Remove from watcher di mode Watcher (cerminan tombol + di All Coins).
    @ViewBuilder
    private func removeFromWatcherButton(for item: PriceItem) -> some View {
        Button {
            if vm.removeFromWatcher(symbol: item.symbol) {
                Task { await vm.refresh(barTitle: barTitle) }
            }
        } label: {
            Image(systemName: "minus.circle.fill")
                .font(.title3)
                .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
        .help("Remove from watcher")
    }

    private static let categoryDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private var categoryUpdatedText: String {
        guard let d = categoryStore.updated else { return "" }
        return Self.categoryDateFormatter.string(from: d)
    }

    // Baris header tab Categories: tombol balik (level 2) + tombol Refresh data
    // khusus data kategori — BUKAN tombol refresh harga di kiri bawah.
    @ViewBuilder
    private var categoryHeaderRow: some View {
        HStack(spacing: 8) {
            if let cat = selectedCategory {
                Button { selectedCategory = nil } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(cat).fontWeight(.semibold)
                    }
                }
                .buttonStyle(.plain)
                Text("• \(categoryCoins.count) coins")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("\(CategoryStore.curatedCategories.count) categories")
                    .font(.callout).fontWeight(.semibold)
                if !categoryUpdatedText.isEmpty {
                    Text("• updated \(categoryUpdatedText)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                Task { await categoryStore.loadIfNeeded(force: true) }
            } label: {
                if categoryStore.isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Label("Refresh data", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            .disabled(categoryStore.isLoading)
            .help("Refresh category data")
        }
        .padding(.horizontal, 12)
    }

    private var profitText: Color {
        colorScheme == .dark ? Color(red: 0.133, green: 0.773, blue: 0.369)
                             : Color(red: 0.086, green: 0.396, blue: 0.204)
    }
    private var lossText: Color {
        colorScheme == .dark ? Color(red: 0.937, green: 0.266, blue: 0.266)
                             : Color(red: 0.725, green: 0.110, blue: 0.110)
    }
    private var profitBg: Color { profitText.opacity(colorScheme == .dark ? 0.28 : 0.14) }

    // Rentang tahun copyright: 2025 (tahun pembuatan) sampai tahun berjalan
    private var copyrightYears: String {
        let year = Calendar.current.component(.year, from: Date())
        return year <= 2025 ? "2025" : "2025–\(year)"
    }
    private var lossBg:   Color { lossText.opacity(colorScheme == .dark ? 0.28 : 0.14) }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image("AppGlyphSmall").resizable().scaledToFit().frame(width: 18, height: 18)
                    Text("CryptoBar Prices").font(.headline)
                }
                Spacer()
                Button {
                    pinned.toggle()
                    StatusBarController.shared.setPinned(pinned)
                } label: { Image(systemName: pinned ? "pin.fill" : "pin").foregroundStyle(.blue) }
                //.buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)

            // Daftar harga
            VStack(spacing: 12) {
                if vm.isLoading { ProgressView().padding(.top, 8) }
                if let err = vm.errorMessage { Text(err).foregroundColor(.red).font(.callout) }

                // Saklar mode daftar: Watcher (pantauan, max 100) | All Coins (rank 1–1200) | Categories
                Picker("", selection: $vm.coinListMode) {
                    Text("Watcher").tag("watcher")
                    Text("All Coins").tag("all")
                    Text("Categories").tag("categories")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, 12)

                // Search daftar harga (tetap di atas, tidak ikut scroll)
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search coins…", text: $searchQuery)
                        .textFieldStyle(.plain)
                    if !searchQuery.isEmpty {
                        Text(searchCountText)
                            .font(.caption2).foregroundStyle(.secondary)
                        Button { searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 12)

                // Header tab Categories: tombol balik + Refresh data (khusus data kategori)
                if isCategories { categoryHeaderRow }

                // ScrollView selalu terpasang supaya tinggi window tidak
                // ikut berubah saat hasil search kosong (window sempat
                // mengecil dan tidak kembali saat ScrollView dilepas).
                ScrollView {
                    if isCategories && selectedCategory == nil {
                        // Level 1 tab Categories: daftar kategori (atau loading/error)
                        if !categoryStore.isLoaded {
                            if categoryStore.isLoading {
                                ProgressView("Loading categories…")
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 24)
                            } else if let catErr = categoryStore.errorMessage {
                                VStack(spacing: 8) {
                                    Text(catErr)
                                        .font(.callout).foregroundStyle(.red)
                                        .multilineTextAlignment(.center)
                                    Button("Retry") {
                                        Task { await categoryStore.loadIfNeeded(force: true) }
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 24)
                            }
                        } else if filteredCategories.isEmpty {
                            Text("No categories match \"\(searchQuery)\"")
                                .font(.callout).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 24)
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredCategories, id: \.self) { name in
                                    let count = categoryStore.count(for: name, from: vm.allItems)
                                    HStack(spacing: 10) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(name).fontWeight(.semibold)
                                            Text("\(count) coins").font(.caption2).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.secondary.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5))
                                    .cornerRadius(8)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedCategory = name }
                                }
                            }
                            .padding(.top, 10)
                        }
                    } else if !isAllCoins && !isCategories && vm.items.isEmpty && !vm.isLoading && vm.errorMessage == nil && searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // Pantauan kosong (mis. semua koin dihapus) — arahkan ke All Coins
                        Text("Watcher is empty — add coins from All Coins.")
                            .font(.callout).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else if filteredItems.isEmpty && !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("No coins match \"\(searchQuery)\"")
                            .font(.callout).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredItems, id: \.id) { item in
                                let change = item.changeDay ?? 0.0
                                let up = change >= 0.0
                                HStack(spacing: 8) {
                                    HStack(spacing: 10) {
                                        AsyncImage(url: item.logoURL) { img in img.resizable().scaledToFill() }
                                        placeholder: { Color.gray.opacity(0.3) }
                                            .frame(width: 22, height: 22)
                                            .clipShape(Circle())

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 4) {
                                                if isAllCoins || isCategories, rank(for: item) > 0 {
                                                    Text("#\(rank(for: item))")
                                                        .font(.caption2.monospaced())
                                                        .foregroundStyle(.secondary)
                                                }
                                                Text(item.id.capitalized).fontWeight(.semibold)
                                            }
                                            Text(item.symbol.uppercased()).font(.caption2).foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(vm.formatCurrency(item.value, vs: vm.vs))
                                                .font(.system(.body, design: .monospaced))
                                            Text(String(format: "%+.2f%%", change))
                                                .font(.caption)
                                                .foregroundStyle(up ? profitText : lossText)
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if let numId = item.cbNumId ?? vm.cbNumericId(for: item.id) {
                                            NotificationCenter.default.post(
                                                name: .openChartsAux,
                                                object: nil,
                                                userInfo: [
                                                    "id": numId,
                                                    "symbol": item.symbol,
                                                    "name": item.id.capitalized,
                                                    "logo": item.logoURL?.absoluteString ?? "",
                                                    "fiat": vm.vs.uppercased(),
                                                    "price": item.value
                                                ]
                                            )
                                        }
                                    }
                                    if isAllCoins || isCategories {
                                        addToWatcherButton(for: item)
                                    }
                                    if !isAllCoins && !isCategories {
                                        removeFromWatcherButton(for: item)
                                    }
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    LinearGradient(colors: up ? [profitBg, .clear] : [lossBg, .clear],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke((up ? profitBg : lossBg).opacity(0.65), lineWidth: 0.5))
                                .cornerRadius(8)
                            }
                    }
                    .padding(.top, 10)
                    }
                }
            }

            // Action bar di atas footer
            Divider()
            HStack(spacing: 14) {
                Button { Task { await vm.refresh(barTitle: barTitle) } } label: {
                    Image(systemName: "arrow.clockwise").foregroundStyle(.green)
                }
                Spacer()
                Button { NotificationCenter.default.post(name: .openSupportAux, object: nil) } label: {
                    Image(systemName: "heart.fill").foregroundStyle(.red)
                }
                Button { NotificationCenter.default.post(name: .openSettingsAux, object: nil) } label: {
                    Image(systemName: "gearshape.fill").foregroundStyle(.gray)
                }
                Spacer()
                Button { EdgePanel.shared.hide() } label: {
                    Image(systemName: "xmark.circle").foregroundStyle(.red)
                }
            }
            .imageScale(.large)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial.opacity(0.12))

            // Footer
            VStack(spacing: 4) {
                Divider()
                Text("© \(copyrightYears) Cmalf-Labs. All rights reserved.")
                    .font(.caption2).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .background(.ultraThinMaterial)
        }
        // Tinggi window dipatok ke ukuran panel (560x670 di EdgePanel)
        // supaya tidak ikut mengecil saat isi daftar berubah.
        .frame(minWidth: 560, minHeight: 670)
        .onAppear {
            Task { @MainActor in
                vm.isLoading = true
                await vm.refresh(barTitle: barTitle)
                vm.isLoading = false
            }
        }
        // Muat data kategori saat masuk tab Categories (sekali saja; cache 24 jam)
        .task(id: vm.coinListMode) {
            if vm.coinListMode == "categories" {
                await categoryStore.loadIfNeeded()
            }
        }
    }
}
