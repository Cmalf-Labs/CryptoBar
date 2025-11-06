/*
 * File: StatusBarController.swift
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
import Combine

@MainActor
final class StatusBarController: NSObject, ObservableObject {
    static let shared = StatusBarController()

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let edgePanel = EdgePanel.shared
    private var cancellables = Set<AnyCancellable>()

    private var barTitle: BarTitle?
    private var vm: CryptoViewModel?

    override init() {
        super.init()
        // Charts
               NotificationCenter.default.addObserver(
                   forName: .openChartsAux, object: nil, queue: .main
               ) { [weak self] note in
                   let info = note.userInfo ?? [:]
                   let id = info["id"] as? Int ?? 0
                   let symbol = info["symbol"] as? String ?? "btc"
                   let name = info["name"] as? String ?? "Bitcoin"
                   let fiat = info["fiat"] as? String ?? "USD"
                   let logoStr = info["logo"] as? String
                   let price = info["price"] as? Double
                   Task { @MainActor [weak self] in
                       guard let self, let vm = self.vm else { return }
                       let charts = CoinDetailView(
                           coinNumId: id,
                           symbol: symbol,
                           coinName: name,
                           logoURL: logoStr.flatMap(URL.init(string:)),
                           fiat: fiat,
                           initialPrice: price
                       ).environmentObject(vm)
                        .id(id)
                       EdgePanel.shared.showAux(charts,
                                                title: "CryptoBar Charts",
                                                symbol: "chart.xyaxis.line",
                                                size: CGSize(width: 560, height: 680))
                   }
               }

               // Settings
               NotificationCenter.default.addObserver(
                   forName: .openSettingsAux, object: nil, queue: .main
               ) { [weak self] _ in
                   Task { @MainActor [weak self] in
                       guard let self, let vm = self.vm, let bar = self.barTitle else { return }
                       let settings = SettingsViewStandalone()
                           .environmentObject(vm)
                           .environmentObject(bar)
                       EdgePanel.shared.showAux(settings,
                                                title: "Settings",
                                                symbol: "gearshape.fill",
                                                size: CGSize(width: 560, height: 680))
                   }
               }

               // Support
               NotificationCenter.default.addObserver(
                   forName: .openSupportAux, object: nil, queue: .main
               ) { _ in
                   Task { @MainActor in
                       let support = SupportViewStandalone()
                       EdgePanel.shared.showAux(support,
                                                title: "Support",
                                                symbol: "heart.fill",
                                                size: CGSize(width: 560, height: 680))
                   }
               }
           }

    func configure(barTitle: BarTitle, vm: CryptoViewModel) {
        self.barTitle = barTitle
        self.vm = vm

        if let button = statusItem.button {
            button.image = NSImage(named: "AppGlyphSmall")
            button.image?.size = NSSize(width: 24, height: 24)
            button.imagePosition = .imageLeft
            button.title = barTitle.text
            button.target = self
            button.action = #selector(togglePanel(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.imagePosition = .imageLeft

            barTitle.$text
                .receive(on: DispatchQueue.main)
                .sink { [weak self] t in self?.statusItem.button?.title = t }
                .store(in: &cancellables)
        }

        vm.start(barTitle: barTitle)
    }
    
    @objc private func menuOpenSettings(_ sender: Any?) {
        NotificationCenter.default.post(name: .openSettingsAux, object: nil)
    }
    
    @objc private func menuOpenSupport(_ sender: Any?) {
        NotificationCenter.default.post(name: .openSupportAux, object: nil)
    }
    
    private func showContextMenu() {
            let menu = NSMenu()

            let support = NSMenuItem(
                title: "Donate",
                action: #selector(menuOpenSupport(_:)),
                keyEquivalent: ""
            )

            if let heartImage = NSImage(systemSymbolName: "heart.fill", accessibilityDescription: "Donate") {
                let tintedImage = heartImage.copy() as! NSImage
                tintedImage.isTemplate = false
                tintedImage.tint(color: .systemRed)
                support.image = tintedImage
            }
            support.target = self
            menu.addItem(support)

            let settings = NSMenuItem(
                title: "Settings",
                action: #selector(menuOpenSettings(_:)),
                keyEquivalent: ","
            )

            if let gearImage = NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: "Settings") {
                settings.image = gearImage
            }
            settings.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
            settings.target = self
            menu.addItem(settings)

            menu.addItem(NSMenuItem.separator())

            // Quit
            let quit = NSMenuItem(
                title: "Quit CryptoBar",
                action: #selector(quitApp),
                keyEquivalent: "q"
            )
            quit.keyEquivalentModifierMask = NSEvent.ModifierFlags.command
            quit.target = self
            menu.addItem(quit)

            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            DispatchQueue.main.async { [weak self] in
                self?.statusItem.menu = nil
            }
        }

    @objc func togglePanel(_ sender: Any?) {
        // Ventura+ (SwiftUI Settings scene)
        if let e = NSApp.currentEvent, e.type == .rightMouseUp {
            showContextMenu()
            return
        }

        // klik kiri
        guard let vm = vm, let barTitle = barTitle else { return }
        let root = MainView()
            .environmentObject(vm)
            .environmentObject(barTitle)
        edgePanel.setRoot(root)
        edgePanel.toggle()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @MainActor
    func presentSheetAlert(_ alert: NSAlert) {
        if let win = EdgePanel.shared.window { alert.beginSheetModal(for: win) { _ in } }
        else { alert.runModal() }
    }

    func setPinned(_ value: Bool) { EdgePanel.shared.setPinned(value) }
}

// MARK: - NSImage Extension untuk Pewarnaan
extension NSImage {
    // Fungsi untuk mewarnai NSImage (hanya untuk macOS modern 10.14+)
    func tint(color: NSColor) {
        lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: self.size)
        imageRect.fill(using: .sourceIn)
        unlockFocus()
    }
}
