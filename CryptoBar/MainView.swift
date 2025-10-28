/*
 * File: MainView.swift
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

import SwiftUI
import Foundation
import AppKit
import ServiceManagement

// MARK: MainView
struct MainView: View {
    @EnvironmentObject var vm: CryptoViewModel
    @EnvironmentObject var barTitle: BarTitle
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme
    
    // UI navigation
    enum Page { case main, settings, support }
    @State private var page: Page = .main
    @State private var pinned = false
    @State private var supportTab: PayTab = .binance
    @State private var toast: String? = nil
    
    @State private var binanceId: String = "96771283"
    @State private var bybitNote: String = "117943952"
    @State private var solanaAddr: String = "SoLMyRa3FGfjSD8ie6bsXK4g4q8ghSZ4E6HQzXhyNGG"
    @State private var evmAddr: String = "0xbeD69b650fDdB6FBB528B0fF7a15C24DcAd87FC4"
    @State private var copied = false   // <- state toast copy
    @State private var coinIDsCSV: String = "btc,eth,xrp,bnb,sol,doge,tron,ada"
    @State private var vs: String = "usd"
    @State private var interval: Int = 30
    
    private let footerHeight: CGFloat = 28
    private let actionBarHeight: CGFloat = 44 // ± tinggi actionBar
    
  
    // MARK: Main Body
    var body: some View {
        VStack(spacing: 0) {
            header
            // Content Area
            VStack {
                switch page {
                case .main:
                    VStack(spacing: 0) {
                        mainPanel
                        // Action Bar hanya di main panel
                        actionBar
                    }
                case .settings: settingsPanel
                case .support: supportPanel
                }
            }
            
            // Footer Copyright (tampil di semua panel)
            footer
        }
        .frame(width: 555, height: 620)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSettings)) { _ in
            page = .settings
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSupport)) { _ in
            page = .support
        }
    }
    
    // MARK: - Panel settings
    private func panelTitle() -> String {
        switch page {
        case .main: return ""
        case .settings: return "Settings"
        case .support: return "Support"
        }
    }
    
    private func panelHeader() -> some View {
        HStack {
            if page != .main {
                Button {
                    page = .main
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back").foregroundStyle(.blue)
                    }
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
            }
            
            Spacer()
            
            Text(panelTitle()).font(.headline)
            
            Spacer()
            
            if page == .main {
                HStack(spacing: 6) {
                    if page == .main {
                        Image("AppGlyphSmall")
                            .resizable().scaledToFit()
                            .frame(width: 18, height: 18)
                        Text("CryptoBar Prices")
                            .font(.headline)
                    } else {
                        // spacer agar tinggi bar sama
                        Color.clear.frame(width: 0, height: 0)
                    }
                    Spacer()
                }
                HStack(spacing: 10) {
                    Button { page = .support } label: {
                        Image(systemName: "heart.fill").foregroundStyle(.red)
                    }
                    Button { page = .settings } label: {
                        Image(systemName: "gearshape.fill").foregroundStyle(.yellow)
                    }
                    Button {
                        pinned.toggle()
                        StatusBarController.shared.setPinned(pinned)
                    } label: {
                        Image(systemName: pinned ? "pin.fill" : "pin")
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.trailing, 12)
            } else {
                Spacer().frame(width: 40)
            }
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: Footer
    private var footer: some View {
        VStack(spacing: 4) {
            Divider()
            Text("© 2025 Cmalf-Labs. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Header common (hanya untuk builder saja haha)
    @ViewBuilder
    private var header: some View {
        panelHeader()
    }
    
    // MARK: Warna semantik untuk gain/loss (teks + latar)
    private var profitText: Color {
        colorScheme == .dark
        ? Color(red: 0.133, green: 0.773, blue: 0.369)    // #22C55E
        : Color(red: 0.086, green: 0.396, blue: 0.204)    // #166534
    }
    private var lossText: Color {
        colorScheme == .dark
        ? Color(red: 0.937, green: 0.266, blue: 0.266)    // #EF4444
        : Color(red: 0.725, green: 0.110, blue: 0.110)    // #B91C1C
    }
    private var profitBg: Color { profitText.opacity(colorScheme == .dark ? 0.28 : 0.14) }
    private var lossBg: Color   { lossText.opacity(colorScheme == .dark ? 0.28 : 0.14) }
    
    // MARK: - Main panel (prices)
    private var mainPanel: some View {
        VStack(spacing: 12) {
            if vm.isLoading { ProgressView().padding(.top, 8) }
            if let err = vm.errorMessage {
                Text(err).foregroundColor(.red).font(.callout)
            }
            // List harga (ScrollView penuh tinggi)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(vm.items, id: \.id) { item in
                        let change = item.changeDay ?? 0.0
                        let up = change >= 0.0
                        
                        HStack(spacing: 10) {
                            AsyncImage(url: item.logoURL) { image in
                                image.resizable().scaledToFill()
                            } placeholder: { Color.gray.opacity(0.3) }
                                .frame(width: 22, height: 22)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.id.capitalized).fontWeight(.semibold)
                                Text(item.symbol.uppercased())
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(vm.formatCurrency(item.value, vs: vm.vs))
                                    .font(.system(.body, design: .monospaced))
                                Text(String(format: "%+.2f%%", change))
                                    .font(.caption)
                                    .foregroundStyle(up ? profitText : lossText)   // <- teks persen adaptif
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(
                            LinearGradient(
                                colors: up ? [profitBg, .clear] : [lossBg, .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke((up ? profitBg : lossBg).opacity(0.65), lineWidth: 0.5)
                        )
                        .cornerRadius(8)
                        .padding(.horizontal, 12)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // agar mengisi tinggi panel
            .onAppear {
                // Bungkus perubahan state di dalam Task; animation opsional
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.isLoading = true
                    }
                    await vm.refresh(barTitle: barTitle)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        vm.isLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - Action Bar
    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 14) {
                // Tombol refresh
                Button {
                    Task { await vm.refresh(barTitle: barTitle) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.green)
                }
                .help("Refresh")
                
                Spacer()
                // Tombol close
                Button {
                    StatusBarController.shared.popover.performClose(nil)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.red)
                }
                .help("Close")
            }
            .imageScale(.large)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Panel Support
    private var supportPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 4) {
                Text("If you enjoy using CryptoBar please consider a donation to help development of the app.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 540)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.12))
                Picker("", selection: $supportTab) {
                    ForEach(PayTab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(8)
            }
            .padding(.horizontal, 12)
            
            // Konten
            Group {
                switch supportTab {
                case .binance:
                    payCard(
                        title: "Scan with Binance App to Pay",
                        qrAsset: "qr_binance",
                        label: "Binance Pay ID",
                        value: binanceId,
                        canCopy: true,
                        //showUserBelowQR: true
                    )
                case .bybit:
                    payCard(
                        title: "Scan with Bybit App to Pay",
                        qrAsset: "qr_bybit",
                        label: "Bybit Pay ID",
                        value: bybitNote,
                        canCopy: true,
                        //showUserBelowQR: true
                    )
                case .solana:
                    payCard(
                        title: "Solana",
                        qrAsset: "qr_solana",
                        label: "SOL Address",
                        value: solanaAddr,
                        canCopy: !solanaAddr.isEmpty,
                        //showUserBelowQR: false
                    )
                case .evm:
                    payCard(
                        title: "EVM",
                        qrAsset: "qr_evm",
                        label: "EVM Address",
                        value: evmAddr,
                        canCopy: !evmAddr.isEmpty,
                        //showUserBelowQR: false
                    )
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomTrailing) {
            // Toast "Copied!" sederhana
            if copied {
                Text("Copied!")
                    .font(.caption).bold()
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.ultraThickMaterial, in: Capsule())
                    .padding(.trailing, 24).padding(.bottom, 28)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: copied)
    }
    
    @ViewBuilder
    private func payCard(
      title: String,
      qrAsset: String,
      label: String,
      value: String,
      canCopy: Bool,
      showUserBelowQR: Bool = false
    ) -> some View {
        VStack(spacing: 14) {
            Text(title).font(.title3).fontWeight(.semibold)
            
            // QR block
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.secondary.opacity(0.08))
                Image(qrAsset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .cornerRadius(12)
                    .padding(18)
            }
            .frame(maxWidth: 380, maxHeight: 380)
            
            /* Teks 'cmalf' tepat di tengah bawah QR
            if showUserBelowQR {
                Text("cmalf")
                    .font(.caption)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }*/
            HStack(spacing: 10) {
                Text("\(label):").font(.callout).foregroundColor(.secondary)
                Text(value.isEmpty ? "—" : value).font(.callout).textSelection(.enabled)
                Spacer()
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(value, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canCopy || value.isEmpty)
            }
            .padding(.horizontal, 6)
        }
    }
    
    // MARK: - Enum Tab Support
    enum PayTab: String, CaseIterable, Identifiable {
        case binance = "Binance Pay"
        case bybit   = "Bybit Pay"
        case solana  = "Solana"
        case evm     = "EVM"
        var id: String { rawValue }
    }
    // MARK: - Settings panel (in-panel)
    @State private var settingsTab: SettingsTab = .general
    enum SettingsTab: String, CaseIterable { case general = "General", updates = "Updates", about = "About" }
    
    @State private var launchAtLogin: Bool = {
        if #available(macOS 13.0, *) { return (SMAppService.mainApp.status == .enabled) }
        return false
    }()
        
    private var settingsPanel: some View {
        VStack(spacing: 16) {
            // Segmented dengan bar biru
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.12))
                Picker("", selection: $settingsTab) {
                    ForEach(SettingsTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(8)
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            
            // Konten tab
            switch settingsTab {
            case .general:
                settingsGeneralCard
            case .updates:
                settingsUpdatesCard
            case .about:
                settingsAboutCard
            }
        }
        .padding(.vertical, 0)
    }
   
    // MARK: - General Cards
    // Chip view
    struct Chip: View {
        let title: String
        let selected: Bool
        var body: some View {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(selected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
                .foregroundStyle(selected ? Color.accentColor : .primary)
                .clipShape(Capsule())
        }
    }
    
    private var fiatCurrencyChipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Fiat Currency", systemImage: "dollarsign.circle.fill")
                .font(.headline)
            
            let codes = ["usd","eur","gbp","brl","pln","jpy","aud","cad","inr","rub","chf","zar","try","krw"]
            
            // Grid adaptif: chip akan wrap ke bawah otomatis
            let cols = [GridItem(.adaptive(minimum: 56), spacing: 8, alignment: .leading)]
            
            LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
                ForEach(codes, id: \.self) { code in
                    Button {
                        vs = code
                    } label: {
                        Chip(title: code.uppercased(), selected: vs == code)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // InfoPanel (ringan)
    struct InfoPanel<Content: View>: View {
        @ViewBuilder var content: Content
        var body: some View {
            content
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(.thinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary, lineWidth: 1))
        }
    }
    
    // MARK: Coins Setup (compact)
    private let defaultCoinsCSV = "btc,eth,xrp,bnb,sol,doge,tron,ada"
    
    private var coinsSetupSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {   // spacing diperkecil
                Label("Coins Setup", systemImage: "bitcoinsign.circle.fill")
                    .font(.headline)
                
                // INFO card (compact)
                InfoPanel {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("INFO:").font(.caption2).fontWeight(.semibold)
                        Text("• Coins: symbol or cg_id, comma-separated, Max: 30")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text("• Only Coins Rank 1–1000 (coingecko)")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text("• First ticker will appear on the menu bar")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 1)              // padding dikompak
                .padding(.bottom, 1)
                
                // Header + Reset
                HStack(spacing: 8) {
                    Text("Coins Ticker").font(.subheadline)
                    Spacer()
                    Button { coinIDsCSV = defaultCoinsCSV } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .padding(6).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Reset to default")
                    .contextMenu {
                        Button("Reset sample") { coinIDsCSV = defaultCoinsCSV }
                        Button("Clear all")     { coinIDsCSV = "" }
                    }
                }
                
                // Input Ticker (tinggi rendah)
                HStack(spacing: 6) {
                    TextField("btc,eth,sol, ...", text: $coinIDsCSV)
                        .font(.system(.callout, design: .monospaced)) // lebih kecil dari .body
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .frame(height: 30) // tinggi kompak
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.12)))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(.quaternary, lineWidth: 1))
                    
                    Button { coinIDsCSV = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Clear")
                }
            }
            .padding(.vertical, 1) // padding card
        }
    }
    // MARK: - Sesi General Cards
    private var settingsGeneralCard: some View {
        SectionCard {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Coins Setup Section
                    coinsSetupSection
                    
                    // Fiat Currency Section
                    fiatCurrencyChipsSection
                    
                    // Update Interval Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Update Interval", systemImage: "clock.arrow.circlepath")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("Every \(interval)s")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(interval) },
                            set: { interval = Int($0) }
                        ), in: 10...300, step: 10)
                        .tint(.blue)
                        
                        HStack {
                            Text("10s")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("300s (5min)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                                        
                    // Apply Button & launchAtLogin SMa
                    HStack {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $launchAtLogin) {
                                Label("Launch at login", systemImage: "power.circle.fill")
                                    .font(.headline)
                            }
                            .toggleStyle(.switch)
                            .tint(.green)
                        }
                        Spacer()
                        Button(action: {
                            // Save ke UserDefaults atau @AppStorage
                            vm.coinIDsCSV = coinIDsCSV
                            vm.vs = vs
                            vm.interval = interval
                            
                            // Restart VM dengan settings baru
                            Task {
                                vm.stop()
                                vm.start(barTitle: barTitle)
                            }
                            
                            // Kembali ke main
                            page = .main
                        }) {
                            Text("Apply")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(minWidth: 100)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                                .padding(.top,10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Update state
    @AppStorage("autoCheckUpdates") private var autoCheckUpdates = true
    @AppStorage("autoDownloadUpdates") private var autoDownloadUpdates = false
    @AppStorage("lastCheckTS") private var lastCheckTS: Double = 0
    @AppStorage("updateIntervalChoice") private var updateIntervalChoice: String = "Monthly"

    private enum UpdateState: Equatable {
        case idle, checking
        case downloading(Double)
        case installing
        case done(String)
        case error(String)
    }
    @State private var updateState: UpdateState = .idle

    private func isDue(_ ts: Double) -> Bool {
        guard ts > 0 else { return true }
        let last = Date(timeIntervalSince1970: ts)
        let cal = Calendar.current
        switch updateIntervalChoice.lowercased() {
        case "daily":   return !cal.isDateInToday(last)
        case "weekly":  return (cal.dateComponents([.day], from: last, to: Date()).day ?? 0) >= 7
        default:        return (cal.dateComponents([.day], from: last, to: Date()).day ?? 0) >= 30
        }
    }
    
    // 1) Versi-compare yang tidak terpotong
    private enum UpdatesHelper {
        static func isNewer(remoteTag: String, local: String) -> Bool {
            func nums(_ v: String) -> [Int] {
                let s = v.trimmingCharacters(in: .whitespaces)
                         .trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                return s.split(separator: ".").compactMap { Int($0) }
            }
            let r = nums(remoteTag), l = nums(local)
            let n = max(r.count, l.count)
            for i in 0..<n {
                let rv = i < r.count ? r[i] : 0
                let lv = i < l.count ? l[i] : 0
                if rv != lv { return rv > lv }
            }
            return false
        }
    }
    // MARK: UPDATESCARD
    private var settingsUpdatesCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 20) {

                // Section: Auto Update
                Label("Automatic Updates", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.headline)
                Toggle("Check for updates automatically", isOn: $autoCheckUpdates)
                    .toggleStyle(.switch)
                    .tint(.blue)
                Text("You will be notified when updates are available.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 2)

                Divider().padding(.vertical, 2)
                
                // Section: Auto Update & install
                Toggle("Auto-download and install updates", isOn: $autoDownloadUpdates)
                    .toggleStyle(.switch)
                    .tint(.blue)
                Text("This action will download and install the update automatically.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 2)
                
                Divider().padding(.vertical, 2)

                // Section: Interval
                Label("Update Check Interval", systemImage: "calendar.badge.clock")
                    .font(.headline)
                    .padding(.top, 6)
                HStack {
                    Text("Check every")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .tint(.gray)
                    //Spacer()
                    Picker("", selection: $updateIntervalChoice) {
                        Text("Daily").tag("Daily")
                        Text("Weekly").tag("Weekly")
                        Text("Monthly").tag("Monthly")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                .font(.subheadline)
                .padding(.leading, 5)

                Divider().padding(.vertical, 2)

                // Section: Manual Update Button
                Button {
                    Task { await handleUpdateIfAvailable() }
                } label: {
                    HStack {
                        if case .checking = updateState {
                            ProgressView().scaleEffect(0.9).padding(.trailing, 6)
                            Text("Checking")
                        } else if case .downloading(let p) = updateState {
                            ProgressView(value: p).frame(width: 120)
                            Text("Downloading \(Int(p * 100))%")
                        } else if case .installing = updateState {
                            ProgressView().scaleEffect(0.9).padding(.trailing, 6)
                            Text("Installing")
                        } else if case .done = updateState {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Check for Updates Now")
                        } else if case .error = updateState {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Try Update Again")
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Check for Updates Now")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled({
                    if case .checking = updateState { return true }
                    if case .downloading = updateState { return true }
                    if case .installing = updateState { return true }
                    return false
                }())

                // Status text
                Text(lastCheckTS == 0
                     ? "Last checked: Never"
                     : "Last checked: \(Date(timeIntervalSince1970: lastCheckTS).formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 10)
            .padding(.top, 5)
            .padding(.bottom, 6)
        }
        .padding(.top, 12)
    }

    @MainActor
    private func handleUpdateIfAvailable() async {
        let local = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        updateState = .checking
        do {
            let rel = try await UpdateManager.shared.fetchLatestRelease(owner: "cmalf-labs", repo: "CryptoBar")
            lastCheckTS = Date().timeIntervalSince1970

            if !UpdatesHelper.isNewer(remoteTag: rel.tag_name, local: local) {
                updateState = .done("Up to date")
                let alert = NSAlert()
                alert.messageText = "You're up to date"
                alert.informativeText = "You already have the latest version of CryptoBar."
                alert.alertStyle = .informational
                await MainActor.run {
                    StatusBarController.shared.presentSheetAlert(alert)
                }
                return
            }
            guard let dmgURL = UpdateManager.shared.pickDMG(from: rel) else {
                updateState = .error("DMG asset not found")
                let alert = NSAlert()
                alert.messageText = "Update asset not found"
                alert.informativeText = "No valid DMG file could be found for the update."
                alert.alertStyle = .critical
                await MainActor.run {
                    StatusBarController.shared.presentSheetAlert(alert)
                }
                return
            }

            if autoDownloadUpdates {
                updateState = .downloading(0)
                let file = try await UpdateManager.shared.downloadDMG(from: dmgURL) { p in
                    Task { @MainActor in updateState = .downloading(p) }
                }
                updateState = .installing
                let appURL = try UpdateManager.shared.installDMG(at: file)
                updateState = .done(rel.tag_name)
                let alert = NSAlert()
                alert.messageText = "Update installed"
                alert.informativeText = "Installed \(rel.tag_name). Relaunching…"
                alert.alertStyle = .informational
                await MainActor.run {
                    StatusBarController.shared.presentSheetAlert(alert)
                }
                try? await Task.sleep(nanoseconds: 600_000_000)
                UpdateManager.shared.relaunch(from: appURL)
            } else {
                if let url = URL(string: rel.html_url) { NSWorkspace.shared.open(url) }
                updateState = .done("Update available: \(rel.tag_name)")
                let alert = NSAlert()
                alert.messageText = "Update available"
                alert.informativeText = "Update \(rel.tag_name) is available."
                alert.alertStyle = .informational
                await MainActor.run {
                    StatusBarController.shared.presentSheetAlert(alert)
                }
            }
        } catch {
            updateState = .error("Update failed")
            let alert = NSAlert()
            alert.messageText = "Update failed"
            alert.informativeText = "Update failed. Please try again later."
            alert.alertStyle = .critical
            await MainActor.run {
                StatusBarController.shared.presentSheetAlert(alert)
            }
        }
    }

    // MARK: AboutCard (compact, left aligned, sticks to footer)
    private var settingsAboutCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 0) {

                // App Icon & Name (center)
                VStack(spacing: 10) {
                    Image(nsImage: NSImage(named: "AppGlyphLarge") ?? NSImage())
                        .resizable()
                        .frame(width: 64, height: 64)

                    Text(Bundle.main.info("CFBundleName").isEmpty ? "CryptoBar" : Bundle.main.info("CFBundleName"))
                        .font(.title3).fontWeight(.semibold)

                    Text("Version \(Bundle.main.info("CFBundleShortVersionString")) (Build \(Bundle.main.info("CFBundleVersion")))")
                        .font(.caption).foregroundStyle(.secondary)

                    Text("Minimal, fast, and privacy-friendly crypto ticker for your Mac menu bar.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 5)
                .padding(.bottom, 2)

                Divider()

                // Open Source Info (center)
                VStack(spacing: 8) {
                    Text("This application is open source and can be found on GitHub:")
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Link(destination: URL(string: "https://github.com/cmalf-labs/CryptoBar")!) {
                        Label("github.com/cmalf-labs/CryptoBar", systemImage: "link")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)

                Divider()

                // Contributors (rata kiri)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Contributors").font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "person.circle.fill").foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Creator").font(.caption).foregroundStyle(.secondary)
                                Text("Cmalf").font(.subheadline).fontWeight(.medium)
                                Text("xcmalf@gmail.com").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "person.circle.fill").foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Publisher").font(.caption).foregroundStyle(.secondary)
                                Text("Panca").font(.subheadline).fontWeight(.medium)
                                Text("panca.rad@icloud.com").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Dorong System Info ke bawah agar mentok footer
                Spacer(minLength: 0)

                Divider()

                // System Info (center)
                VStack(spacing: 2) {
                    Text("System Information").font(.caption).foregroundStyle(.secondary)
                    Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
            }
            // Penting: biar Spacer bekerja dan kartu mengisi area konten
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }


    // MARK: - Helpers Toast
    private func showToast(_ text: String) {
            toast = text
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { toast = nil }
        }
    }

    // Kartu section dengan latar material dan garis halus
    private struct SectionCard<Content: View>: View {
        @ViewBuilder var content: Content
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(.thinMaterial)
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                VStack(alignment: .leading, spacing: 2) {
                    content
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
    }


// MARK: - Bundle helper (file scope)
extension Bundle { func info(_ key: String) -> String { infoDictionary?[key] as? String ?? "" } }
