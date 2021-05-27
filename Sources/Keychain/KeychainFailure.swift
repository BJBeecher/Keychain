//
//  File.swift
//  
//
//  Created by BJ Beecher on 5/26/21.
//

import AuthenticationServices

public enum KeychainFailure : Error {
    case itemNotfound
    case badStatus(OSStatus)
}
