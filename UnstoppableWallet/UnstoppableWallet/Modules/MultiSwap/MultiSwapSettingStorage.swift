import Foundation
import MarketKit

class MultiSwapSettingStorage {
    private var modifiedSettings = [String: Any]()

    func value<T>(for key: String) -> T? {
        modifiedSettings[key] as? T
    }

    func set(value: Any?, for key: String) {
        if let value {
            modifiedSettings[key] = value
        } else {
            modifiedSettings[key] = nil
        }
    }

    func recipient(blockchainType: BlockchainType) -> Address? {
        value(for: "recipient-\(recipientUid(blockchainType: blockchainType))")
    }

    func set(recipient: Address?, blockchainType: BlockchainType) {
        set(value: recipient, for: "recipient-\(recipientUid(blockchainType: blockchainType))")
    }

    private func recipientUid(blockchainType: BlockchainType) -> String {
        if EvmBlockchainManager.blockchainTypes.contains(blockchainType) {
            return "evm"
        }

        return blockchainType.uid
    }
}

extension MultiSwapSettingStorage {
    enum LegacySetting {
        static let slippage = "slippage"
    }
}
