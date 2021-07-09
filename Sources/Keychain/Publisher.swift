//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/27/21.
//

import Foundation
import Combine

public extension Publisher where Output : Codable {
    func saveToKeychain<Key: Hashable>(forKey key: Key, keychain: KeychainClient = .init()) -> AnyPublisher<Output, Failure> {
        handleEvents(receiveOutput: { output in
            try? keychain.insert(output, forKey: key)
        }).eraseToAnyPublisher()
    }
}
