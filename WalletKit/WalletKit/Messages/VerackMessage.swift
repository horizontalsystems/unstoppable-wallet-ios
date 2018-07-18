//
//  VerackMessage.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

/// The verack message is sent in reply to version.
/// This message consists of only a message header with the command string "verack".
public struct VerackMessage {
    public func serialized() -> Data {
        return Data()
    }
}
