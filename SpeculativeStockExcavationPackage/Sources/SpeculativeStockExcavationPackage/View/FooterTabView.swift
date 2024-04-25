//
//  FooterTabView.swift
//
//
//  Created by 佐川 晴海 on 2024/04/25.
//

import SwiftUI

struct FooterTabView: View {
    @State private var selection: Int = 1
    
    var body: some View {
        NavigationView {
            TabView(selection: $selection) {
                PriceRiseView()
                    .tabItem {
                        Label("値上がり銘柄", systemImage: "chart.xyaxis.line")
                    }
                    .tag(1)
                    
                
                FavoriteView()
                    .tabItem {
                        Label("お気に入り", systemImage: "star")
                    }
                    .tag(2)
            }
            .navigationTitle(selection == 1 ? "仕手株発掘🔨" : "")
        }
    }
    
    
}

#Preview {
    FooterTabView()
}
