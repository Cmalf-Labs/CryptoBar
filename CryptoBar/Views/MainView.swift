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

    private var profitText: Color {
        colorScheme == .dark ? Color(red: 0.133, green: 0.773, blue: 0.369)
                             : Color(red: 0.086, green: 0.396, blue: 0.204)
    }
    private var lossText: Color {
        colorScheme == .dark ? Color(red: 0.937, green: 0.266, blue: 0.266)
                             : Color(red: 0.725, green: 0.110, blue: 0.110)
    }
    private var profitBg: Color { profitText.opacity(colorScheme == .dark ? 0.28 : 0.14) }
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
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.items, id: \.id) { item in
                            let change = item.changeDay ?? 0.0
                            let up = change >= 0.0
                            HStack(spacing: 10) {
                                AsyncImage(url: item.logoURL) { img in img.resizable().scaledToFill() }
                                placeholder: { Color.gray.opacity(0.3) }
                                    .frame(width: 22, height: 22)
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.id.capitalized).fontWeight(.semibold)
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
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(
                                LinearGradient(colors: up ? [profitBg, .clear] : [lossBg, .clear],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke((up ? profitBg : lossBg).opacity(0.65), lineWidth: 0.5))
                            .cornerRadius(8)
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
                        }
                    }
                    .padding(.top, 10)
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
                Text("© 2025 Cmalf-Labs. All rights reserved.")
                    .font(.caption2).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .background(.ultraThinMaterial)
        }
        .onAppear {
            Task { @MainActor in
                vm.isLoading = true
                await vm.refresh(barTitle: barTitle)
                vm.isLoading = false
            }
        }
    }
}
