/*
 * File: SupportViewStandalone.swift
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

struct SupportViewStandalone: View {
    // MARK: - Enum Tab Support
    enum PayTab: String, CaseIterable, Identifiable {
        case binance = "Binance Pay"
        case bybit   = "Bybit Pay"
        case solana  = "Solana"
        case evm     = "EVM"
        var id: String { rawValue }
    }
    @State private var supportTab: PayTab = .binance
    
    @State private var binanceId: String = "96771283"
    @State private var bybitNote: String = "117943952"
    @State private var solanaAddr: String = "SoLMyRa3FGfjSD8ie6bsXK4g4q8ghSZ4E6HQzXhyNGG"
    @State private var evmAddr: String = "0xbeD69b650fDdB6FBB528B0fF7a15C24DcAd87FC4"
    @State private var copied = false   // <- state toast copy
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 4) {
                Text("If you enjoy using CryptoBar please consider a donation to help development of the app.")
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 550)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.1))
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
                        title: "Scan with Binance App to Donate",
                        qrAsset: "qr_binance",
                        label: "Binance Pay ID",
                        value: binanceId,
                        canCopy: true,
                        //showUserBelowQR: true
                    )
                case .bybit:
                    payCard(
                        title: "Scan with Bybit App to Donate",
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
}

