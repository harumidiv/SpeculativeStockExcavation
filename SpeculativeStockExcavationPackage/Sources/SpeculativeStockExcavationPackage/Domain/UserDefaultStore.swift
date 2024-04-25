//
//  UserDefaultStore.swift
//  SpaculativeStockScrayping
//
//  Created by 佐川 晴海 on 2024/04/22.
//

import Foundation

protocol UserDefaultStore {
    func saveFavoriteList(saveItem: FavoriteModel)
    func getFavoriteList() -> [FavoriteModel]
    func deleteFavoriteList(deleteItem: FavoriteModel)
}


final class UserDefaultStoreImpl: UserDefaultStore {
    public static let share = UserDefaultStoreImpl()
    
    private init() {}
    
    func saveFavoriteList(saveItem: FavoriteModel) {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        let saveModelList = getFavoriteList() + [saveItem]
        guard let data = try? jsonEncoder.encode(saveModelList) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "favorite")
    }
    
    func getFavoriteList() -> [FavoriteModel] {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let data = UserDefaults.standard.data(forKey: "favorite"),
              let dataModel = try? jsonDecoder.decode([FavoriteModel].self, from: data) else {
            return []
        }
        return dataModel
    }
    
    func deleteFavoriteList(deleteItem: FavoriteModel) {
        var currentFavoriteList = getFavoriteList()
        currentFavoriteList.removeAll(where: { $0.name == deleteItem.name})
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        guard let data = try? jsonEncoder.encode(currentFavoriteList) else {
            return
        }
        UserDefaults.standard.set(data, forKey: "favorite")
    }
}
