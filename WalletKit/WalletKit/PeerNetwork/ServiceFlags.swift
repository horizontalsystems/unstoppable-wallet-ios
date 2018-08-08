//
//  ServiceFlags.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

struct ServiceFlags : OptionSet {
    let rawValue: UInt64
    /// Nothing
    static let none = ServiceFlags(rawValue: 0)
    /// NODE_NETWORK means that the node is capable of serving the complete block chain. It is currently
    /// set by all Bitcoin Core non pruned nodes, and is unset by SPV clients or other light clients.
    static let network = ServiceFlags(rawValue: 1 << 0)
    /// NODE_GETUTXO means the node is capable of responding to the getutxo protocol request.
    /// Bitcoin Core does not support this but a patch set called Bitcoin XT does.
    /// See BIP 64 for details on how this is implemented.
    static let getutxo = ServiceFlags(rawValue: 1 << 1)
    /// NODE_BLOOM means the node is capable and willing to handle bloom-filtered connections.
    /// Bitcoin Core nodes used to support this by default, without advertising this bit,
    /// but no longer do as of protocol version 70011 (= NO_BLOOM_VERSION)
    static let bloom = ServiceFlags(rawValue: 1 << 2)
    /// NODE_WITNESS indicates that a node can be asked for blocks and transactions including
    /// witness data.
    static let witness = ServiceFlags(rawValue: 1 << 3)
    /// NODE_XTHIN means the node supports Xtreme Thinblocks
    /// If this is turned off then the node will not service nor make xthin requests
    static let xthin = ServiceFlags(rawValue: 1 << 4)
    /// NODE_NETWORK_LIMITED means the same as NODE_NETWORK with the limitation of only
    /// serving the last 288 (2 day) blocks
    /// See BIP159 for details on how this is implemented.
    static let networkLimited = ServiceFlags(rawValue: 1 << 10)
    // Bits 24-31 are reserved for temporary experiments. Just pick a bit that
    // isn't getting used, or one not being used much, and notify the
    // bitcoin-development mailing list. Remember that service bits are just
    // unauthenticated advertisements, so your code must be robust against
    // collisions and other cases where nodes may be advertising a service they
    // do not actually support. Other service bits should be allocated via the
    // BIP process.
}

extension ServiceFlags : CustomStringConvertible {
    var description: String {
        let strings = ["NODE_NETWORK", "NODE_GETUTXO", "NODE_BLOOM", "NODE_WITNESS", "NODE_XTHIN", "NODE_NETWORK_LIMITED"]
        var members = [String]()
        for (flag, string) in strings.enumerated() where self.contains(ServiceFlags(rawValue: 1 << (UInt8(flag)))) {
            members.append(string)
        }
        return members.joined(separator: "|")
    }
}
