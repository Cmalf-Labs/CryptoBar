/*
 * File: CoinDetailView.swift
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
import Charts
import Combine

// MARK: - ViewModel
@MainActor
final class CoinDetailVM: ObservableObject {
    @Published var range: ChartRange = .day
    @Published var points: [ChartPoint] = []
    @Published var metrics: BubbleMetrics?
    @Published var loading = false
    @Published var error: String?

    let coinNumId: Int
    let symbol: String
    let fiat: String

    init(coinNumId: Int, symbol: String, fiat: String) {
        self.coinNumId = coinNumId
        self.symbol = symbol
        self.fiat = fiat
    }

    var latestPrice: Double? { metrics?.p ?? points.last?.p }

    func loadAll() async {
        await loadMetrics()
        await loadChart()
    }

    func loadChart() async {
        loading = true
        defer { loading = false }
        do {
            points = try await ChartsService.shared.fetchChart(coinNumId: coinNumId, fiat: fiat, range: range)
        } catch {
            self.error = "Failed to load chart data."
        }
    }

    func loadMetrics() async {
        do {
            metrics = try await ChartsService.shared.fetchMetrics(
                fiat: fiat,
                coinNumId: coinNumId,
                symbol: symbol
            )
        } catch {
            self.error = "Failed to load metrics."
        }
    }
}

// MARK: - Main View
struct CoinDetailView: View {
    @EnvironmentObject private var appVM: CryptoViewModel
    @StateObject private var vm: CoinDetailVM

    let coinName: String
    let logoURL: URL?
    let initialPrice: Double?
    let changeDay: Double?

    @State private var coinAmount = "1"
    @State private var fiatAmount = ""
    @FocusState private var focused: Field?
    private enum Field { case coin, fiat }

    init(coinNumId: Int, symbol: String, coinName: String, logoURL: URL?, fiat: String, initialPrice: Double?, changeDay: Double? = nil) {
        _vm = StateObject(wrappedValue: CoinDetailVM(coinNumId: coinNumId, symbol: symbol, fiat: fiat))
        self.coinName = coinName
        self.logoURL = logoURL
        self.initialPrice = initialPrice
        self.changeDay = changeDay
    }
    
    private var rangeChangePct: Double? {
        guard let first = vm.points.first?.p,
              let last  = vm.points.last?.p,
              first > 0 else { return nil }
        return (last - first) / first * 100.0
    }

    private var effectivePrice: Double? { vm.latestPrice ?? initialPrice }
    @State private var hoverDate: Date? = nil
    @State private var hoverPrice: Double? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 8)

            converter
                .padding(.horizontal, 16)
                .padding(.top, 16)

            stats
                .padding(.horizontal, 16)
                .padding(.top, 12)

            chart
                .frame(minHeight: 240, maxHeight: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .clipped()

            Spacer(minLength: 12)

            customRangePicker
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
        .frame(minWidth: 560, minHeight: 560)
        .task {
            await vm.loadAll()
            recalcFromCoin()
            focused = .coin
        }
        .task(id: vm.range) { await vm.loadChart() }
    }
}

// MARK: - UI Components (Extension)
extension CoinDetailView {
    private var header: some View {
        HStack(spacing: 12) {
            AsyncImage(url: logoURL) { $0.resizable().scaledToFill() } placeholder: { Color.gray.opacity(0.2) }
                .frame(width: 28, height: 28)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(coinName).font(.title3.weight(.semibold))
                Text(vm.symbol.uppercased()).font(.callout).foregroundStyle(.secondary)
            }

            Spacer()

            Text(effectivePrice.map { appVM.formatCurrency($0, vs: appVM.vs) } ?? "—")
                .font(.title2.weight(.bold))
            if let pct = rangeChangePct ?? changeDay {
                Text(String(format: "%+.2f%%", pct))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(pct >= 0 ? .green : .red)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var converter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Converter", systemImage: "arrow.left.arrow.right.circle")
                .font(.headline)

            HStack(spacing: 12) {
                HStack {
                    Text(vm.symbol.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
                    TextField("1.0", text: $coinAmount)
                        .textFieldStyle(.plain).multilineTextAlignment(.trailing)
                }
                .padding(10).background(Capsule().fill(Color.secondary.opacity(0.12)))
                .focused($focused, equals: .coin)
                .onChangeCompat(of: coinAmount) { _ in if focused == .coin { recalcFromCoin() } }

                Image(systemName: "equal").foregroundStyle(.secondary)

                HStack {
                    Text(vm.fiat.uppercased()).font(.caption.bold()).foregroundStyle(.secondary)
                    TextField("0.00", text: $fiatAmount)
                        .textFieldStyle(.plain).multilineTextAlignment(.trailing)
                }
                .padding(10).background(Capsule().fill(Color.secondary.opacity(0.12)))
                .focused($focused, equals: .fiat)
                .onChangeCompat(of: fiatAmount) { _ in if focused == .fiat { recalcFromFiat() } }
            }
        }
    }

    private var stats: some View {
        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 6) {
            GridRow {
                HStack { Text("Rank").foregroundStyle(.secondary); Text(intOrDash(vm.metrics?.r)) }
                HStack { Text("Market Cap").foregroundStyle(.secondary); Text(compactFiat(vm.metrics?.mc)) }
                HStack { Text("Volume").foregroundStyle(.secondary); Text(compactFiat(vm.metrics?.v)) }
            }
        }.font(.subheadline)
    }

    @ViewBuilder private var chart: some View {
        if vm.loading && vm.points.isEmpty { ProgressView() }
        else if vm.points.isEmpty { Text("No chart data available.").frame(maxWidth: .infinity, maxHeight: .infinity) }
        else {
            let (_, trend, minP, maxP) = chartStats()
            let fill = LinearGradient(colors: [trend.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)

            Chart(vm.points) { pt in
                AreaMark(x: .value("Date", pt.date), y: .value("Price", pt.p))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(fill)

                LineMark(x: .value("Date", pt.date), y: .value("Price", pt.p))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .foregroundStyle(trend)

                if let d = hoverDate, let p = hoverPrice {
                    ruleAndPointMarks(d, p)
                }
            }
            .chartYScale(domain: (minP * 0.99)...(maxP * 1.01))
            .chartOverlay { proxy in chartDragOverlay(proxy) }
            .clipped()
            .overlay(alignment: .topLeading) {
                highLowOverlay(maxP: maxP, minP: minP)
                    .padding(.leading, 8)   // jarak dari tepi kiri plot area
                    .padding(.top, 8)       // jarak dari tepi atas
            }
        }
    }

    private var customRangePicker: some View {
        HStack {
            ForEach(ChartRange.allCases) { range in
                Button(range.title) { vm.range = range }
                    .font(.body.weight(.medium))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(vm.range == range ? Color.blue : Color.clear)
                    .foregroundStyle(vm.range == range ? .white : .primary)
                    .clipShape(Capsule())
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.15))
        .clipShape(Capsule())
    }

    // MARK: - Chart Subviews & Helpers
    
    private func chartStats() -> (Bool, Color, Double, Double) {
        guard let firstP = vm.points.first?.p, let lastP = vm.points.last?.p,
              let minP = vm.points.map(\.p).min(), let maxP = vm.points.map(\.p).max() else {
            return (true, .gray, 0, 0)
        }
        let isUp = lastP >= firstP
        return (isUp, isUp ? .green : .red, minP, maxP)
    }

    @ChartContentBuilder
    private func ruleAndPointMarks(_ d: Date, _ p: Double) -> some ChartContent {
        RuleMark(x: .value("Date", d)).foregroundStyle(.secondary.opacity(0.5))
        PointMark(x: .value("Date", d), y: .value("Price", p))
            .foregroundStyle(.primary)
            .symbolSize(30)
            .annotation(position: .top, alignment: .center) {
                VStack(spacing: 2) {
                    Text(d.formatted(date: .numeric, time: vm.range == .hour ? .shortened : .omitted))
                    Text(appVM.formatCurrency(p, vs: appVM.vs))
                }
                .font(.caption).padding(6).background(.ultraThinMaterial).cornerRadius(6)
            }
    }

    private func chartDragOverlay(_ proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let frame = geo[proxy.plotAreaFrame]
                        guard frame.contains(value.location) else { return }
                        let x = value.location.x - frame.origin.x
                        if let d: Date = proxy.value(atX: x),
                           let nearest = vm.points.min(by: { abs($0.date.distance(to: d)) < abs($1.date.distance(to: d)) }) {
                            hoverDate = nearest.date
                            hoverPrice = nearest.p
                        }
                    }
                    .onEnded { _ in
                        hoverDate = nil
                        hoverPrice = nil
                    }
                )
        }
    }

    private func highLowOverlay(maxP: Double, minP: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("High: \(appVM.formatCurrency(maxP, vs: appVM.vs))")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.85)))
                .foregroundStyle(.white)

            Text("Low:  \(appVM.formatCurrency(minP, vs: appVM.vs))")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(Color.red.opacity(0.85)))
                .foregroundStyle(.white)
        }
        .padding(8)
    }

    // MARK: - Other Helpers
    private func parseCleanDecimal(_ s: String) -> Decimal? {
        let filtered = s.replacingOccurrences(of: ",", with: "")
        
        guard !filtered.isEmpty,
              filtered != ".",
              let d = Decimal(string: filtered, locale: Locale(identifier: "en_US_POSIX"))
        else {
            if filtered.last == "." {
                return Decimal(string: String(filtered.dropLast()),
                               locale: Locale(identifier: "en_US_POSIX"))
            }
            return nil
        }
        return d
    }

    private func recalcFromCoin() {
        guard let price = effectivePrice, price > 0 else { return }
        
        guard let c = parseCleanDecimal(coinAmount) else {
            // Jika input tidak valid (misal kosong), set fiat ke "0"
            fiatAmount = appVM.formatCurrency(0, vs: appVM.vs)
            return
        }
        
        let fiatValue = (c as NSDecimalNumber).multiplying(by: NSDecimalNumber(value: price))
        fiatAmount = appVM.formatCurrency(fiatValue.doubleValue, vs: appVM.vs)
    }

    private func recalcFromFiat() {
        guard let price = effectivePrice, price > 0 else { return }

        // String fiat mungkin mengandung simbol
        // mata uang, jadi kita filter dulu.
        let digits = fiatAmount.filter { "0123456789.,".contains($0) }
        guard let f = parseCleanDecimal(digits) else {
            // Jika input tidak valid (misal kosong), set koin ke "0"
            coinAmount = "0"
            return
        }
        
        let coinValue = (f as NSDecimalNumber).dividing(by: NSDecimalNumber(value: price))
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = "" // Tidak pakai separator ribuan
        formatter.decimalSeparator = "."
        
        coinAmount = formatter.string(from: coinValue) ?? ""
    }

    private func intOrDash(_ n: Int?) -> String { n.map(String.init) ?? "—" }

    private func compactFiat(_ v: Double?) -> String {
        guard let x = v, x > 0 else { return "—" }
        let units: [(Double, String)] = [(1e12, "T"), (1e9, "B"), (1e6, "M"), (1e3, "K")]
        let prefix = appVM.vs.uppercased() == "USD" ? "$" : ""
        for (limit, suffix) in units where x >= limit {
            return String(format: "\(prefix)%.2f\(suffix)", x / limit)
        }
        return appVM.formatCurrency(x, vs: appVM.vs)
    }
}
extension View {
    @ViewBuilder
    func onChangeCompat<T: Equatable>(of value: T, perform: @escaping (T) -> Void) -> some View {
        if #available(macOS 14.0, *) {
            self.onChange(of: value, initial: false) { _, newValue in
                perform(newValue)
            }
        } else {
            self.onChange(of: value) { newValue in
                perform(newValue)
            }
        }
    }
}

