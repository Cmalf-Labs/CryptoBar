/*
 * File: EdgePanel.swift
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

final class EdgePanel: NSWindowController {
    static let shared = EdgePanel()

    // Layout
    private let mainSize = NSSize(width: 560, height: 670)
    private let topInset: CGFloat = 8
    private let sideMargin: CGFloat = 8
    private let gutter: CGFloat = 12

    private var isShown = false
    private var pinned = false
    private var outsideMonitor: Any?

    private lazy var hosting = NSHostingView(rootView: AnyView(EmptyView()))
    private lazy var auxHosting = NSHostingView(rootView: AnyView(EmptyView()))

    // Container blur untuk panel utama
    private lazy var container: NSVisualEffectView = {
        let v = NSVisualEffectView()
        v.material = .hudWindow
        v.state = .active
        v.wantsLayer = true
        v.layer?.cornerRadius = 22
        if #available(macOS 13.0, *) { v.layer?.cornerCurve = .continuous }
        v.layer?.masksToBounds = true
        return v
    }()

    // Panel 1 (main)
    private lazy var panel: NSPanel = {
        let p = NSPanel(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isOpaque = false
        p.backgroundColor = .clear
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.hidesOnDeactivate = false
        p.hasShadow = true
        p.contentView = container
        container.addSubview(hosting)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return p
    }()

    // Panel 2 (aux)
    private lazy var auxPanel: NSPanel = {
        let p = NSPanel(contentRect: .zero, styleMask: [.borderless, .titled], backing: .buffered, defer: false)
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isOpaque = false
        p.backgroundColor = .clear
        p.titleVisibility = .hidden
        p.titlebarAppearsTransparent = true
        p.hasShadow = true
        p.hidesOnDeactivate = false
        let fx = NSVisualEffectView()
        fx.material = .hudWindow
        fx.state = .active
        fx.wantsLayer = true
        fx.layer?.cornerRadius = 22
        if #available(macOS 13.0, *) { fx.layer?.cornerCurve = .continuous }
        fx.layer?.masksToBounds = true
        fx.addSubview(auxHosting)
        auxHosting.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            auxHosting.leadingAnchor.constraint(equalTo: fx.leadingAnchor),
            auxHosting.trailingAnchor.constraint(equalTo: fx.trailingAnchor),
            auxHosting.topAnchor.constraint(equalTo: fx.topAnchor),
            auxHosting.bottomAnchor.constraint(equalTo: fx.bottomAnchor)
        ])
        p.contentView = fx
        return p
    }()

    // Shell header + footer untuk konten panel 2
    struct AuxShell<Content: View>: View {
        let title: String
        let symbol: String?
        @ViewBuilder var content: Content
        var body: some View {
            VStack(spacing: 0) {
                ZStack {
                    HStack { Spacer() } // kiri kosong agar center sejati
                    HStack(spacing: 8) {
                        if let s = symbol { Image(systemName: s).foregroundStyle(title == "Support" ? Color.red : (title == "CryptoBar Charts" ? Color.green : Color.gray))
                                                        }
                        Text(title).font(.headline)
                    }
                    HStack {
                        Spacer()
                        Button {
                            EdgePanel.shared.hideAux()
                        } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.red) }
                        //.buttonStyle(.plain)
                        .padding(.trailing, 12)
                    }
                }
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)

                content

                VStack(spacing: 4) {
                    Divider()
                    Text("© 2025 Cmalf-Labs. All rights reserved.")
                        .font(.caption2).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .background(.ultraThinMaterial)
            }
        }
    }

    // Public API
    func setRoot<V: View>(_ view: V) { hosting.rootView = AnyView(view) }

    func setPinned(_ value: Bool) {
        pinned = value
        if pinned { removeOutsideClickMonitor() } else { installOutsideClickMonitorIfNeeded() }
    }

    func toggle() { isShown ? hide() : show() }

    func show() {
        guard let screen = currentScreen() else { return }
        let f = frames(on: screen)
        panel.setFrame(NSRect(x: f.end.origin.x, y: f.end.origin.y, width: mainSize.width, height: mainSize.height), display: true)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22; ctx.allowsImplicitAnimation = true
            panel.animator().setFrame(f.end, display: true)
        }
        isShown = true
        if !pinned { installOutsideClickMonitorIfNeeded() }
    }

    func hide() {
        guard let screen = currentScreen() else { return }
        let f = frames(on: screen)
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.18; ctx.allowsImplicitAnimation = true
            panel.animator().setFrame(f.start, display: true)
            panel.animator().alphaValue = 0
        }, completionHandler: {
            self.panel.orderOut(nil); self.panel.alphaValue = 1
        })
        isShown = false
        hideAux()
        removeOutsideClickMonitor()
    }

    func showAux<V: View>(_ view: V, title: String, symbol: String?, size: CGSize) {
            guard let screen = currentScreen() else { return }
            auxHosting.rootView = AnyView(AuxShell(title: title, symbol: symbol) { view })
            let mainEnd = frames(on: screen).end
            let auxEnd = NSRect(x: mainEnd.minX - gutter - size.width,
                                y: mainEnd.minY,
                                width: size.width,
                                height: size.height)
            let auxStart = auxEnd.offsetBy(dx: mainEnd.width + size.width + 36, dy: 0)
            auxPanel.setFrame(auxStart, display: true)
            NSApp.activate(ignoringOtherApps: true)
            auxPanel.makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.22; ctx.allowsImplicitAnimation = true
                auxPanel.animator().setFrame(auxEnd, display: true)
            }
        }

    func hideAux() { auxPanel.orderOut(nil) }

    // Helpers
    private func frames(on screen: NSScreen) -> (start: NSRect, end: NSRect) {
        let vf = screen.visibleFrame
        let end = NSRect(x: vf.maxX - mainSize.width - sideMargin,
                         y: vf.maxY - mainSize.height - topInset,
                         width: mainSize.width, height: mainSize.height)
        let start = end.offsetBy(dx: mainSize.width + 24, dy: 0)
        return (start, end)
    }

    private func currentScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
    }

    private func installOutsideClickMonitorIfNeeded() {
        guard outsideMonitor == nil else { return }
        outsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.isShown, !self.pinned else { return }
            self.hide()
        }
    }

    private func removeOutsideClickMonitor() {
        if let m = outsideMonitor { NSEvent.removeMonitor(m); outsideMonitor = nil }
    }
}
