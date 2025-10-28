/*
 * File: CryptoBarApp.swift
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

@main
struct CryptoBarApp: App {
    
    let barTitle = BarTitle()
    let vm = CryptoViewModel()

    init() {
        StatusBarController.shared.configure(barTitle: barTitle, vm: vm)
    }

    var body: some Scene {
        Settings { EmptyView() } // tidak membuat window reguler
    }
}
