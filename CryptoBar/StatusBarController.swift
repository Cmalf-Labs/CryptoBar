/*
 * File: StatusBarController.swift
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
import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject, ObservableObject {
    static let shared = StatusBarController()
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let popover = NSPopover()
    @Published var pinned: Bool = false
    
    private var barTitle: BarTitle?
    private var vm: CryptoViewModel?
    private var cancellables = Set<AnyCancellable>()
    private let fixedSize = NSSize(width: 555, height: 620)
    
    private var globalMonitor: Any?

    private func installMonitorIfNeeded() {
        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                guard let self = self else { return }
                if self.popover.isShown && !self.pinned { self.popover.performClose(nil) }
            }
        }
    }

    private func removeMonitor() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
    }
    
    func configure(barTitle: BarTitle, vm: CryptoViewModel) {
        installMonitorIfNeeded()
        self.barTitle = barTitle
        self.vm = vm
        
        let content = MainView()
            .environmentObject(vm)
            .environmentObject(barTitle)
        let host = NSHostingController(rootView: content)
        popover.contentViewController = host
        popover.behavior = .transient
        popover.contentSize = fixedSize
        popover.behavior = pinned ? .applicationDefined : .transient
        
        if let button = statusItem.button {
            button.image = NSImage(named: "AppGlyphSmall")
            button.image?.size = NSSize(width: 24, height: 24)
            button.imagePosition = .imageLeft
            button.title = barTitle.text
            barTitle.$text
                .receive(on: DispatchQueue.main)
                .sink { [weak self] t in self?.statusItem.button?.title = t }
                .store(in: &cancellables)

            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        vm.start(barTitle: barTitle)
    }
    
    @objc func togglePopover(_ sender: Any?) {
        guard let e = NSApp.currentEvent else { return toggleDefault(sender) } // fallback
        if e.type == .rightMouseUp { showMenu(); return }                       // klik kanan = menu
        toggleDefault(sender)                                                   // klik kiri = toggle
    }

    private func toggleDefault(_ sender: Any?) {
        if popover.isShown { popover.performClose(sender) }
        else if let b = statusItem.button {
            popover.show(relativeTo: b.bounds, of: b, preferredEdge: .minY)
        }                                                                       // toggle aman
    }

    private func showMenu() {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        let donateItem = NSMenuItem(title: "Donate", action: #selector(openDonate), keyEquivalent: "")
        donateItem.target = self
        let quitItem = NSMenuItem(title: "Quit CryptoBar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        [settingsItem, donateItem, NSMenuItem.separator(), quitItem].forEach(menu.addItem)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { self.statusItem.menu = nil }                 // reset setelah tampil
    }

    @objc private func openSettings() {
        if !popover.isShown, let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        NotificationCenter.default.post(name: .navigateToSettings, object: nil)
    }

    @objc private func openDonate() {
        if !popover.isShown, let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
        NotificationCenter.default.post(name: .navigateToSupport, object: nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func setPinned(_ on: Bool) {
        pinned = on
        popover.behavior = on ? .applicationDefined : .transient            // mode pin
        if on { removeMonitor() } else { installMonitorIfNeeded() }
    }
    
    func setPopoverSize(_ size: NSSize) {
        popover.contentSize = size
    }
   // MARK: NsAlert
    @MainActor
    func presentSheetAlert(_ alert: NSAlert) {
        if let win = StatusBarController.shared.popover.contentViewController?.view.window {
            alert.beginSheetModal(for: win) { _ in }
        } else {
            alert.runModal()
        }
    }
}

// Extension Notification.Name
extension Notification.Name {
    static let navigateToSettings = Notification.Name("navigateToSettings")
    static let navigateToSupport = Notification.Name("navigateToSupport")
}
