//
//  FavoriteModel.swift
//  
//
//  Created by 佐川 晴海 on 2024/04/25.
//

import Foundation

struct FavoriteModel: Codable, Identifiable {
    var id = UUID()
    var url: String
    var name: String
}
