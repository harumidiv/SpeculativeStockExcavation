//
//  ContentView.swift
//  SpeculativeStockExcavation
//
//  Created by 佐川 晴海 on 2024/04/25.
//

import SwiftUI
import SwiftSoup

struct FavoriteModel: Codable, Identifiable {
    var id = UUID()
    var url: String
    var name: String
}

struct StockData: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let price: Int?
    let priceIncreaseRate: String
}

struct ContentView: View {
    @State private var stockURL: URL?
    @State private var spaculativeStockList: [StockData] = []
    @State private var selection: Int = 1
    @State private var favoriteList: [FavoriteModel] = UserDefaultStoreImpl.share.getFavoriteList()
    
    var body: some View {
        TabView(selection: $selection) {
            NavigationView {
                scraypingView()
            }
            .navigationTitle("仕手株発掘🔨")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if !spaculativeStockList.isEmpty {
                            Button(action: {
                                spaculativeStockList = []
                                scraypingPriceIncreceRateRanking()
                            }, label: {
                                Image(systemName: "arrow.clockwise")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            })
                        }
                    }
                }
            }
            .tabItem {
                Label("値上がり銘柄", systemImage: "chart.xyaxis.line")
            }
            .tag(1)
            
            favoriteView(favoriteList: $favoriteList)
                .onAppear {
                    favoriteList = UserDefaultStoreImpl.share.getFavoriteList()
                }
                .tabItem {
                    Label("お気に入り", systemImage: "star")
                }
                .tag(2)
        }
        .onAppear {
            scraypingPriceIncreceRateRanking()
        }
    }
}

// MARK: View
extension ContentView {
    private func favoriteView(favoriteList: Binding<[FavoriteModel]>) -> some View {
        List(favoriteList) { stock in
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
                    favoriteList.wrappedValue = UserDefaultStoreImpl.share.getFavoriteList()
                }
                .tint(.red)
            }
        }
    }
    
    @ViewBuilder
    private func scraypingView() -> some View {
        if spaculativeStockList.isEmpty {
            ProgressView()
                .frame(width: 100, height: 100)
        } else {
            List(spaculativeStockList) { stock in
                Group {
                    Link(destination: URL(string: stock.url + "/chart")!, label: {
                        HStack {
                            Text(stock.name)
                            Spacer()
                            Text(stock.priceIncreaseRate)
                        }
                        .padding()
                    })
                    .openURLInSafariView()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        UserDefaultStoreImpl.share.saveFavoriteList(saveItem: FavoriteModel(url: stock.url + "/chart", name: stock.name))
                    } label: {
                        Text("お気に入り")
                    }
                    .tint(.yellow)
                }
                .refreshable {
                    spaculativeStockList = []
                    scraypingPriceIncreceRateRanking()
                }
            }
        }
    }
}

// MARK: Process
extension ContentView {
    private func scraypingPriceIncreceRateRanking() {
        Task.detached {
            let html = await fetchHtml(url: URL(string: "https://finance.yahoo.co.jp/stocks/ranking/up")!)
            let document = try SwiftSoup.parse(html)
            do {
                let list = try document.select("div._1IdtoV3i._3WzzJnld").select("tbody").select("tr")
                
                let stockList: [StockData] = try list.compactMap { stock in
                    let url = try stock.select("a").attr("href")
                    let name = try stock.select("a")[0].text()
                    let priceIncreaseRate = try stock.select("span._1fofaCjs._2aohzPlv._1cYUswbE").select("span._1-yujUee._1ekLn9XO").select("span._3rXWJKZF").text()
                    let price = try stock
                        .select("span._1fofaCjs._2aohzPlv.g8s8KhAD")
                        .select("span._1-yujUee")
                        .select("span._3rXWJKZF")[0].text()
                    
                    return .init(name: name,
                                 url: url,
                                 price: Int(price.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()),
                                 priceIncreaseRate: priceIncreaseRate)
                }
                
                var spaculativeStock: [StockData] = []
                for await stockInfo in fetchHtmlStream(stockList: stockList) {
                    if let price = stockInfo.stock.price { // 2000円以上の株を弾く
                        if price >= 2000 {
                            continue
                        }
                    }
                    
                    let stockDocument = try SwiftSoup.parse(stockInfo.html)
                    
                    let marketCapitalization = try stockDocument
                        .select("div._1IdtoV3i._1eM32nld")
                        .select("div._3gfVrz4p._3hJ55Ncb")
                        .select("section._3QnSv6hl.v421ieSL")
                        .select("div._1IdtoV3i.r1zYWIKI")
                        .select("ul._3U1XwIwJ")
                        .select("li")
                        .select("dl._38iJU1zx._2pSv51JU")
                        .select("dd._1m_13krb")
                        .select("span._1fofaCjs._2aohzPlv._1DMRub9m")
                        .select("span._1-yujUee")
                        .select("span._3rXWJKZF._11kV6f2G")[0].text()
                    
                    if marketCapitalization.count >= 6 { // 100億以上を弾く
                        continue
                    }
                    
                    
                    
                    spaculativeStock.append(stockInfo.stock)
                }
                
                spaculativeStockList = spaculativeStock
            } catch {
                print("error")
            }
        }
    }
    
    private func fetchHtmlStream(stockList: [StockData]) -> AsyncStream<(stock: StockData, html: String)> {
        AsyncStream { continuation in
            Task {
                for stock in stockList {
                    let html = await fetchHtml(url: URL(string: stock.url)!)
                    continuation.yield((stock: stock, html: html))
                }
                continuation.finish()
            }
        }
    }
    
    private func fetchHtml(url: URL) async -> String {
        do {
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            if let htmlString = String(data: data, encoding: .utf8) {
                return htmlString
            }
        } catch {
            print("error")
        }
        return ""
    }
}

#Preview {
    ContentView()
}
