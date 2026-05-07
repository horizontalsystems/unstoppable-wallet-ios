//
//  Adapted from aa-swift (MIT License)
//  https://github.com/syn-mcj/aa-swift
//  Copyright (c) 2024 aa-swift
//
//  Reimplemented for unstoppable-wallet-ios:
//  - Top-level fields only; nested `receipt: TxReceipt` and `logs: [Log]`
//    are parsed later in the UserOperationSender flow (Part 18).
//

import Foundation

/// Response from bundler `eth_getUserOperationReceipt`.
/// Contains the user-operation-level fields; transaction receipt and logs
/// are handled separately by the sender pipeline.
public struct UserOperationReceipt: Equatable, Codable {
    public let userOpHash: String
    public let entryPoint: String
    public let sender: String
    public let nonce: String
    public let paymaster: String?
    public let actualGasCost: String
    public let actualGasUsed: String
    public let success: Bool
    public let reason: String?

    public init(
        userOpHash: String,
        entryPoint: String,
        sender: String,
        nonce: String,
        paymaster: String?,
        actualGasCost: String,
        actualGasUsed: String,
        success: Bool,
        reason: String?
    ) {
        self.userOpHash = userOpHash
        self.entryPoint = entryPoint
        self.sender = sender
        self.nonce = nonce
        self.paymaster = paymaster
        self.actualGasCost = actualGasCost
        self.actualGasUsed = actualGasUsed
        self.success = success
        self.reason = reason
    }
}
