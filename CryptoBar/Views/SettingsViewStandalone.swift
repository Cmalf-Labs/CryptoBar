/*
 * File: SettingsViewStandalone.swift
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
import ServiceManagement
import AppKit

struct SettingsViewStandalone: View {
    @EnvironmentObject var vm: CryptoViewModel
    @EnvironmentObject var barTitle: BarTitle

    @State private var settingsTab: SettingsTab = .general
    @State private var toast: String? = nil
    @State private var updateState: UpdateState = .idle
    enum SettingsTab: String, CaseIterable { case general = "General", updates = "Updates", about = "About" }

    // General
    @AppStorage("coinIDsCSV") private var coinIDsCSV = "btc,eth,xrp,bnb,sol,doge,tron,ada"
    @AppStorage("vs") private var vs = "usd"
    @AppStorage("interval") private var interval = 30
    @State private var workingCoinIDsCSV: String = "" // buffer manual apply
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = {
        if #available(macOS 13.0, *) { return (SMAppService.mainApp.status == .enabled) }
        return false
    }()

    // Updates
    @AppStorage("autoCheckUpdates") private var autoCheckUpdates = true
    @AppStorage("autoDownloadUpdates") private var autoDownloadUpdates = false
    @AppStorage("lastCheckTS") private var lastCheckTS: Double = 0
    @AppStorage("updateIntervalChoice") private var updateIntervalChoice: String = "Monthly"
    
    // MARK: - Update state
    private enum UpdateState: Equatable {
        case idle, checking
        case downloading(Double)
        case installing
        case done(String)
        case error(String)
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                 RoundedRectangle(cornerRadius: 12)
                     .fill(Color.blue.opacity(0.1))
                 Picker("", selection: $settingsTab) {
                     ForEach(SettingsTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                 }
                 .pickerStyle(.segmented)
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
         .padding(.vertical, 6)
         .background(.thinMaterial.opacity(0.1))
         .onAppear {
             workingCoinIDsCSV = coinIDsCSV
         }
     }

    // MARK: - General Cards
    // Chip view
    struct Chip: View {
        let title: String
        let selected: Bool
        var body: some View {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(selected ? .white : .primary)
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
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.green.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.quaternary, lineWidth: 1))
        }
    }
    
    // MARK: Coins Setup (compact)
    private var coinsSetupSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Coins Setup", systemImage: "bitcoinsign.circle.fill")
                    .font(.headline)

                HStack(alignment: .top, spacing: 12) {

                    InfoPanel {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("INFO:").font(.caption2).fontWeight(.semibold)
                            Text("• Coins: symbol or cg_id, Max: 30")
                                .font(.caption2).foregroundStyle(.secondary)
                            Text("• Only Coins Rank 1–1000 (coingecko)")
                                .font(.caption2).foregroundStyle(.secondary)
                            Text("• First ticker will appear on the menu bar")
                                .font(.caption2).foregroundStyle(.secondary)
                            Text("• Simply enter the coin's ticker, press enter, or click the add button")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 240)

                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.08))
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.quaternary, lineWidth: 1)

                        // Input Ticker
                        HStack(spacing: 6) {
                            CoinsCompactSelector(csv: $workingCoinIDsCSV, vs: vs)
                                .padding(.top, 4)
                                .background(.thinMaterial.opacity(0.1))
                        }
                        .padding(.vertical, 1) // padding card
                    }
                    .frame(minHeight: 148) // ruang ekstra untuk token area + tombol
                    .clipped()
                }
            }
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
                            // Commit manual
                            coinIDsCSV = workingCoinIDsCSV
                            vm.coinIDsCSV = workingCoinIDsCSV
                            vm.vs = vs
                            vm.interval = interval

                            // Restart VM agar main panel menerapkan perubahan
                            Task {
                                vm.stop()
                                vm.start(barTitle: barTitle)
                            }
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
    
    // 1) Versi-compare
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
        .padding(.top, 5)
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

                    Text("CryptoBar is a lightweight and user-friendly macOS menu bar application for tracking real-time cryptocurrency prices.")
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
                VStack(spacing: 6) {
                    Text("This application is open source and can be found on GitHub:")
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 8) {
                        Image(systemName: "link").foregroundStyle(.blue)
                            .frame(width: 14, alignment: .center)
                        Link("github.com/cmalf-labs/CryptoBar",
                             destination: URL(string: "https://github.com/cmalf-labs/CryptoBar")!)
                            .font(.subheadline).foregroundStyle(.blue).buttonStyle(.plain)
                    }
                    /*HStack(spacing: 8) {
                        Image(systemName: "link").foregroundStyle(.blue)
                            .frame(width: 14, alignment: .center)
                        Link("github.com/cmalf/CryptoBar",
                             destination: URL(string: "https://github.com/cmalf/CryptoBar")!)
                            .font(.subheadline).foregroundStyle(.blue).buttonStyle(.plain)
                    }*/
                }
                .fixedSize() // biar selebar konten
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
                    .fill(.thinMaterial.opacity(0.11))
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                VStack(alignment: .leading, spacing: 6) {
                    content
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
            }
        }
    }


// MARK: - Bundle helper (file scope)
extension Bundle { func info(_ key: String) -> String { infoDictionary?[key] as? String ?? "" }
}
