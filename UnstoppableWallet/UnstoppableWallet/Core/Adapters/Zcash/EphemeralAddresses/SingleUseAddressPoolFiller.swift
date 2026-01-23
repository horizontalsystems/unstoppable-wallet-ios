// SingleUseAddressPoolFiller.swift

import Foundation
import HsToolKit
import ZcashLightClientKit

actor SingleUseAddressPoolFiller {
    private static let maxGenerationAttempts: Int = 50

    private static let gapLimitErrorPatterns: [String] = [
        "could not be safely reserved",
        "gap limit",
        "The proposal cannot be constructed",
    ]

    private let synchronizer: Synchronizer
    private let storage: ZcashAdapterStorage
    private let walletId: String
    private let logger: HsToolKit.Logger?

    private var accountId: AccountUUID?

    init(
        synchronizer: Synchronizer,
        storage: ZcashAdapterStorage,
        walletId: String,
        logger: HsToolKit.Logger? = nil
    ) {
        self.synchronizer = synchronizer
        self.storage = storage
        self.walletId = walletId
        self.logger = logger

        logger?.log(level: .debug, message: "AddressPoolFiller: Initialized")
    }

    func set(accountId: AccountUUID) {
        self.accountId = accountId
    }

    func fill() async throws -> Int {
        guard let accountId else {
            throw AddressError.noAccountId
        }

        logger?.log(level: .debug, message: "AddressPoolFiller: fill() - Starting")

        var generatedCount = 0
        var attemptCount = 0
        var shouldContinue = true

        while shouldContinue, attemptCount < Self.maxGenerationAttempts {
            attemptCount += 1

            do {
                let address = try await generateAddress(accountId: accountId)
                generatedCount += 1

                logger?.log(level: .debug, message: "AddressPoolFiller: fill() - Generated [\(generatedCount)]: gapIndex=\(address.gapIndex), addr=\(address.address)")

            } catch {
                if isGapLimitError(error) {
                    logger?.log(level: .debug, message: "AddressPoolFiller: fill() - ✅ SDK limit reached: \(error)")
                    shouldContinue = false
                } else {
                    logger?.log(level: .error, message: "AddressPoolFiller: fill() - ❌ Unexpected error: \(error)")
                    throw error
                }
            }
        }

        if attemptCount >= Self.maxGenerationAttempts {
            logger?.log(level: .warning, message: "AddressPoolFiller: fill() - ⚠️ Reached max attempts (\(Self.maxGenerationAttempts))")
        }

        logger?.log(level: .debug, message: "AddressPoolFiller: fill() - ✅ Completed: generated \(generatedCount) addresses in \(attemptCount) attempts")

        return generatedCount
    }

    private func generateAddress(accountId: AccountUUID) async throws -> SingleUseAddress {
        let sdkAddress = try await synchronizer.getSingleUseTransparentAddress(accountUUID: accountId)

        guard let addressString = sdkAddress.addressString else {
            logger?.log(level: .error, message: "AddressPoolFiller: Failed to extract addressString")
            throw AddressError.invalidAddressData
        }

        guard let gapPosition = sdkAddress.gapPosition else {
            logger?.log(level: .error, message: "AddressPoolFiller: Failed to extract gapPosition")
            throw AddressError.invalidAddressData
        }

        guard let gapLimit = sdkAddress.gapLimit else {
            logger?.log(level: .error, message: "AddressPoolFiller: Failed to extract gapLimit")
            throw AddressError.invalidAddressData
        }

        let address = SingleUseAddress(
            walletId: walletId,
            address: addressString,
            gapIndex: gapPosition,
            gapLimit: gapLimit,
            timestamp: Date()
        )

        let savedAddress = try storage.save(address: address)

        logger?.log(level: .debug, message: "AddressPoolFiller: Saved address [gapIndex: \(gapPosition), gapLimit: \(gapLimit)]: \(addressString)")

        return savedAddress
    }

    private func isGapLimitError(_ error: Error) -> Bool {
        guard case let .rustGetSingleUseTransparentAddress(error) = error as? ZcashLightClientKit.ZcashError else {
            return false
        }

        return Self.gapLimitErrorPatterns.contains { pattern in
            error.range(of: pattern, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}

extension SingleUseAddressPoolFiller {
    enum AddressError: LocalizedError {
        case noAccountId
        case invalidAddressData

        var errorDescription: String? {
            switch self {
            case .noAccountId:
                return "AddressPoolFiller: AccountId not setted"
            case .invalidAddressData:
                return "AddressPoolFiller: Invalid address data from SDK"
            }
        }
    }
}
