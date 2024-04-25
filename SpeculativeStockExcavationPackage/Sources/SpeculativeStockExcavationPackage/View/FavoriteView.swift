//
//  SwiftUIView.swift
//  
//
//  Created by 佐川 晴海 on 2024/04/25.
//

import SwiftUI

struct FavoriteView: View {
    @State private var favoriteList: [FavoriteModel] = UserDefaultStoreImpl.share.getFavoriteList()
    
    var body: some View {
        List($favoriteList) { stock in
            Link(destination: URL(string: stock.url.wrappedValue)!, label: {
                HStack {
                    Text(stock.name.wrappedValue)
                    Spacer()
                }
                .padding()
            })
            .openURLInSafariView()
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button("削除") {
                    UserDefaultStoreImpl.share.deleteFavoriteList(deleteItem: stock.wrappedValue)
                    favoriteList = UserDefaultStoreImpl.share.getFavoriteList()
                }
                .tint(.red)
            }
        }
        .onAppear {
            favoriteList = UserDefaultStoreImpl.share.getFavoriteList()
        }
    }
}

#Preview {
    FavoriteView()
}
