/*
 * File: TokenField.swift
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

struct TokenField: NSViewRepresentable {
    // Binding daftar simbol yang dipilih (mis. ["btc","eth"])
    @Binding var tokens: [String]

    // Sumber saran: boleh simbol atau cg_id; canonical: symbol lowercase
    let allowedSymbols: Set<String>
    let idToSymbol: [String: String]   // cg_id -> symbol
    let limit: Int = 30

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSTokenField {
        let tf = NSTokenField()
        tf.tokenStyle = .rounded
        tf.delegate = context.coordinator
        tf.completionDelay = 0.0
        tf.tokenizingCharacterSet = CharacterSet(charactersIn: ", ")
        tf.placeholderString = "Type to search coins (BTC / bitcoin / …)"
        tf.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        tf.focusRingType = .none
        tf.alignment = .left
        tf.usesSingleLineMode = false            // bisa wrap singkat
        tf.lineBreakMode = .byWordWrapping
        context.coordinator.updateField(tf)
        return tf
    }

    func updateNSView(_ nsView: NSTokenField, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateField(nsView)
    }

    final class Coordinator: NSObject, NSTokenFieldDelegate {
        var parent: TokenField
        init(_ parent: TokenField) { self.parent = parent }

        // Render dari model -> UI
        func updateField(_ tf: NSTokenField) {
            tf.objectValue = parent.tokens.map { $0.uppercased() }
        }

        // Auto-complete menu saat user mengetik
        private func tokenField(_ tokenField: NSTokenField,
                        completionsForSubstring substring: String,
                        indexOfToken tokenIndex: Int,
                        indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>?) -> [String]? {
            let q = substring.lowercased().trimmingCharacters(in: .whitespaces)
            guard !q.isEmpty else { return [] }
            // dukung cari via symbol atau cg_id
            var hits = [String]()
            // match symbol
            hits += parent.allowedSymbols
                .filter { $0.contains(q) }
                .prefix(12)
                .map { $0.uppercased() }
            // match cg_id -> symbol
            if hits.count < 12 {
                let more = parent.idToSymbol
                    .filter { $0.key.contains(q) }
                    .map { $0.value }
                    .filter { !hits.map({ $0.lowercased() }).contains($0) }
                    .prefix(12 - hits.count)
                hits += more.map { $0.uppercased() }
            }
            return hits
        }

        // Normalisasi dan batasi 30 token saat ditambah
        func tokenField(_ tokenField: NSTokenField,
                        shouldAdd tokens: [Any],
                        at index: Int) -> [Any] {
            var current = parent.tokens
            var accepted: [String] = []
            for any in tokens {
                let raw = String(describing: any).lowercased()
                guard !raw.isEmpty else { continue }
                let sym = parent.allowedSymbols.contains(raw) ? raw
                         : (parent.idToSymbol[raw] ?? raw)
                // hanya terima jika termasuk sumber data 1–1000
                guard parent.allowedSymbols.contains(sym) else { continue }
                // batasi 30 dan hindari duplikat
                guard !current.contains(sym), current.count + accepted.count < parent.limit else { continue }
                accepted.append(sym.uppercased())
            }
            // sinkronkan ke binding
            if !accepted.isEmpty {
                current.append(contentsOf: accepted.map { $0.lowercased() })
                parent.tokens = current
            }
            return accepted
        }

        // Hapus token -> perbarui binding
        func tokenField(_ tokenField: NSTokenField,
                        didRemove tokens: [Any],
                        at index: Int) {
            let removed = tokens.map { String(describing: $0).lowercased() }
            parent.tokens.removeAll { removed.contains($0) || removed.contains($0.lowercased()) }
        }

        // Ketika user edit manual dan tekan pemisah, map ke represented object
        func tokenField(_ tokenField: NSTokenField,
                        representedObjectForEditing editingString: String) -> Any? {
            let raw = editingString.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if parent.allowedSymbols.contains(raw) { return raw.uppercased() }
            if let sym = parent.idToSymbol[raw] { return sym.uppercased() }
            return nil // tolak yang di luar 1–1000
        }
    }
}
