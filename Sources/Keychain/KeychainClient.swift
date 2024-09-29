//
//  KeyChainServices.swift
//  BJApp
//
//  Created by BJ Beecher on 12/11/19.
//  Copyright © 2019 BJ Beecher. All rights reserved.
//

import AuthenticationServices

public final class KeychainClient {
    typealias AddItem = (_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    typealias UpdateItem = (_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus
    typealias FetchItem = (_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    typealias DeleteItem = (_ query: CFDictionary) -> OSStatus
    
    
    let addItem : AddItem
    let updateItem : UpdateItem
    let fetchItem : FetchItem
    let deleteItem : DeleteItem
    
    let encoder : JSONEncoder
    let decoder : JSONDecoder
    
    init(
        addItem: @escaping AddItem,
        updateItem: @escaping UpdateItem,
        fetchItem: @escaping FetchItem,
        deleteItem: @escaping DeleteItem,
        encoder: JSONEncoder,
        decoder: JSONDecoder
    ){
        self.addItem = addItem
        self.updateItem = updateItem
        self.fetchItem = fetchItem
        self.deleteItem = deleteItem
        self.encoder = encoder
        self.decoder = decoder
    }
    
    public convenience init() {
        self.init(addItem: SecItemAdd, updateItem: SecItemUpdate, fetchItem: SecItemCopyMatching, deleteItem: SecItemDelete, encoder: .init(), decoder: .init())
    }
}

// public API

public extension KeychainClient {
    
    /// Creates a new keychain record (throws if exists)
    /// - Parameters:
    ///   - value: value to insert
    ///   - key: key describing value
    func insert<Value: Codable>(_ value: Value, forKey key: String) throws {
        // format value for acceptable insert
        let data = try encoder.encode(value)
        // create insert query
        let query : [String : Any] = [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrAccount as String : key, // must use account key as primary key for searchability -- attrLabel will not work
            kSecValueData as String : data
        ]
        // run query
        let status = addItem(query as CFDictionary, nil)
        // check status
        switch status {
            case errSecDuplicateItem:
                try updateValue(with: value, forKey: key)
            case errSecSuccess:
                return
            default:
                throw KeychainFailure.badStatus(status)
        }
    }
    
    
    /// Inserts if does not exist and updates if does
    /// - Parameters:
    ///   - value: value to insert/update
    ///   - key: key for query
    func save<Value: Codable>(_ value: Value, forKey key: String) throws {
        do {
            try insert(value, forKey: key)
        } catch let error as KeychainFailure {
            guard case .badStatus(let status) = error, status == errSecDuplicateItem else {
                throw error
            }
            
            try updateValue(with: value, forKey: key)
        } catch {
            throw error
        }
    }
    
    
    /// Updates existing value in keychain using key to lookup
    /// - Parameters:
    ///   - newValue: value to replace existing value
    ///   - key: key to find value
    func updateValue<Value: Codable>(with newValue: Value, forKey key: String) throws {
        // format value for acceptable insert
        let newData = try encoder.encode(newValue)
        // create the search query
        let searchQuery : [String : Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String : key
        ]
        // create query
        let updateQuery : [String : Any] = [
            kSecValueData as String : newData
        ]
        // run update query
        let status = updateItem(searchQuery as CFDictionary, updateQuery as CFDictionary)
        // throw unsuccessful updates
        if status != errSecSuccess {
            throw KeychainFailure.badStatus(status)
        }
    }
    
    /// fetches value saved on keychain
    /// - Parameter key: key for query
    /// - Returns: value to fetch
    func value<Value: Codable>(forKey key: String) throws -> Value? {
        // specify query to run against keychain
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ] as [String : Any]
        // create an item to copy to from the keychain
        var item: CFTypeRef?
        // run query and attach result to item
        let status = fetchItem(query as CFDictionary, &item)
        // check status
        switch status {
        case errSecItemNotFound:
            return nil
        case errSecSuccess:
            let dict = item as? [String : Any]
            guard let data = dict?[kSecValueData as String] as? Data else { return nil }
            let value = try decoder.decode(Value.self, from: data)
            return value
        default:
            throw KeychainFailure.badStatus(status)
        }
    }
    
    /// deletes item on keychain
    /// - Parameter key: key for query
    func deleteValue(forKey key: String) throws {
        // query for the item to delete
        let query : [String : Any] = [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
        ]
        // run the delete query
        let status = deleteItem(query as CFDictionary)
        // check status of query
        if status != errSecSuccess {
            throw KeychainFailure.badStatus(status)
        }
    }
    
    subscript<Value: Codable>(key: String) -> Value? {
        get {
            try? value(forKey: key)
        } set {
            if let value = newValue {
                try? insert(value, forKey: key)
            } else {
                try? deleteValue(forKey: key)
            }
        }
    }
}
