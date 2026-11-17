/*
 * File: PriceAlerts.swift
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
 *
 * Price alert satu kali pakai (one-shot): saat harga melewati target,
 * muncul notifikasi macOS sekali, lalu alert dihapus otomatis supaya
 * tidak spam tiap refresh (30 detik). Satu alert per koin.
 * Alert dicek di CryptoViewModel.refresh() setelah harga terbaru terisi.
 * Alert untuk koin yang sudah tidak dipilih lagi ikut dihapus saat dicek.
 */

import Foundation
import Combine
import UserNotifications

struct PriceAlert: Codable, Identifiable, Equatable {
    enum Direction: String, Codable, CaseIterable {
        case above, below
    }

    var id: UUID
    var symbol: String      // lowercase, mis. "bnb"
    var coinName: String    // mis. "Bnb" — untuk isi notifikasi
    var target: Double
    var direction: Direction
    var fiat: String        // mis. "usd" — untuk format harga di notifikasi
    var createdAt: Date
}

@MainActor
final class PriceAlertStore: ObservableObject {
    static let shared = PriceAlertStore()

    private let defaultsKey = "priceAlerts"
    @Published private(set) var alerts: [PriceAlert] = []

    private init() { load() }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([PriceAlert].self, from: data)
        else { return }
        alerts = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(alerts) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }

    func alert(for symbol: String) -> PriceAlert? {
        alerts.first { $0.symbol == symbol.lowercased() }
    }

    func setAlert(symbol: String, coinName: String, target: Double, direction: PriceAlert.Direction, fiat: String) {
        let sym = symbol.lowercased()
        alerts.removeAll { $0.symbol == sym }   // satu alert per koin
        alerts.append(PriceAlert(id: UUID(), symbol: sym, coinName: coinName,
                                 target: target, direction: direction,
                                 fiat: fiat, createdAt: Date()))
        save()
        requestAuthorizationIfNeeded()
    }

    func removeAlert(for symbol: String) {
        alerts.removeAll { $0.symbol == symbol.lowercased() }
        save()
    }

    // Dipanggil tiap refresh selesai, setelah vm.items terisi.
    func checkAndNotify(items: [(symbol: String, price: Double)]) {
        guard !alerts.isEmpty else { return }

        // Bersihkan alert untuk koin yang sudah tidak dipilih lagi
        let tracked = Set(items.map { $0.symbol.lowercased() })
        alerts.removeAll { !tracked.contains($0.symbol) }

        var fired: [(alert: PriceAlert, current: Double)] = []
        for alert in alerts {
            guard let item = items.first(where: { $0.symbol.lowercased() == alert.symbol }) else { continue }
            let crossed = alert.direction == .above
                ? item.price >= alert.target
                : item.price <= alert.target
            if crossed { fired.append((alert, item.price)) }
        }
        guard !fired.isEmpty else { save(); return }

        // One-shot: hapus yang sudah bunyi supaya tidak spam tiap refresh
        alerts.removeAll { a in fired.contains { $0.alert.id == a.id } }
        save()
        for entry in fired { notify(alert: entry.alert, currentPrice: entry.current) }
    }

    // MARK: - Notifikasi macOS

    // true kalau notifikasi diizinkan (atau belum ditanya — akan diminta saat set alert)
    func notificationsAllowed() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    private func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
            }
        }
    }

    private func notify(alert: PriceAlert, currentPrice: Double) {
        let content = UNMutableNotificationContent()
        content.title = "CryptoBar — \(alert.coinName)"
        let verb = alert.direction == .above ? "above" : "below"
        content.body = "\(alert.coinName) crossed \(verb) \(formatPrice(alert.target, fiat: alert.fiat)) — now \(formatPrice(currentPrice, fiat: alert.fiat))"
        content.sound = .default

        let request = UNNotificationRequest(identifier: alert.id.uuidString,
                                            content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func formatPrice(_ v: Double, fiat: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = fiat.uppercased()
        if v >= 1 {
            f.maximumFractionDigits = 2
            f.minimumFractionDigits = 2
        } else if v >= 0.01 {
            f.maximumFractionDigits = 4
            f.minimumFractionDigits = 2
        } else {
            f.maximumFractionDigits = 6
            f.minimumFractionDigits = 2
        }
        return f.string(from: NSNumber(value: v)) ?? "\(v) \(fiat.uppercased())"
    }
}
