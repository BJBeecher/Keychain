//
//  KeychainItem.swift
//  Luna
//
//  Created by BJ Beecher on 9/14/20.
//  Copyright © 2020 Renaissance Technologies. All rights reserved.
//

import Foundation

@propertyWrapper
public struct KeychainItem<T: Codable> {
    
    private let key : String
    
    private let keychainService : KeychainClient
    
    public init(_ forKey: String, keychainService: KeychainClient = .init()){
        // set key for getting and adding item
        key = forKey
        // set service
        self.keychainService = keychainService
        // set wrapped value
        wrappedValue = try? keychainService.value(forKey: key)
    }
    
    public var wrappedValue : T? {
        willSet {
            if let item = newValue {
                try? keychainService.insert(item, forKey: key)
            } else {
                try? keychainService.deleteValue(forKey: key)
            }
        }
    }
}
