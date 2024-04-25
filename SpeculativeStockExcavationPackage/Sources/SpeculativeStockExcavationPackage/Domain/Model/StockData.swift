//
//  File.swift
//  
//
//  Created by 佐川 晴海 on 2024/04/25.
//

import Foundation

struct StockData: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let price: Int?
    let priceIncreaseRate: String
}
