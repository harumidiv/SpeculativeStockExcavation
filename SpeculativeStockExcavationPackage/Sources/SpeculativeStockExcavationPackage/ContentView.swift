//
//  ContentView.swift
//  SpeculativeStockExcavation
//
//  Created by 佐川 晴海 on 2024/04/25.
//

import SwiftUI
import SwiftSoup

struct StockData: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let price: Int?
    let priceIncreaseRate: String
}

public struct ContentView: View {
    public var body: some View {
        FooterTabView()
    }
    
    public init() {}
}

#Preview {
    ContentView()
}
