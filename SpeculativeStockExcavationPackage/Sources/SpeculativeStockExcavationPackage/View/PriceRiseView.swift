//
//  PriceRiseView.swift
//
//
//  Created by 佐川 晴海 on 2024/04/25.
//

import SwiftUI
import SwiftSoup

struct PriceRiseView: View {
    @State private var spaculativeStockList: [StockData] = []
    
    var body: some View {
        contentView()
            .onAppear {
                scraypingPriceIncreceRateRanking()
            }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
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
                    
                    
                    if let marketCapitalization = try stockDocument
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
                        .select("span._3rXWJKZF._11kV6f2G").first {
                        
                        if try marketCapitalization.text().count >= 6 { // 100億以上を弾く
                            continue
                        }
                        
                        spaculativeStock.append(stockInfo.stock)
                    }
                }
                
                spaculativeStockList = spaculativeStock
            } catch {
                print("error: \(error)")
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
    PriceRiseView()
}
