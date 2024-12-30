import BigInt
import Combine
import Eip20Kit
import EvmKit
import Foundation
import MarketKit
import NftKit
import RxSwift

class SpamAddressManager {
    private let storage: SpamAddressStorage
    private let coinManager: CoinManager
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    private let coinValueLimits: [String: Decimal] = AppConfig.spamCoinValueLimits
    private let coins: [FullCoin]

    init(storage: SpamAddressStorage, marketKit: MarketKit.Kit, coinManager: CoinManager) {
        self.storage = storage
        self.coinManager = coinManager
        coins = (try? marketKit.fullCoins(coinUids: Array(coinValueLimits.keys))) ?? []
    }

    private func scanSpamAddresses(fullTransaction: FullTransaction, userAddress: EvmKit.Address, spamConfig: SpamConfig) -> [EvmKit.Address] {
        let transaction = fullTransaction.transaction
        let baseCoinValue = spamConfig.baseCoinValue
        let coinsMap = spamConfig.coinsMap
        let blockchainType = spamConfig.blockchainType

        switch fullTransaction.decoration {
        case let decoration as IncomingDecoration:
            if let from = transaction.from, decoration.value <= baseCoinValue {
                return [from]
            }

        case let decoration as UnknownTransactionDecoration:
            if transaction.from == userAddress {
                return []
            } else if transaction.to != userAddress {
                var spamAddresses = [EvmKit.Address]()

                let internalTransactions = decoration.internalTransactions.filter { $0.to == userAddress }
                let (totalIncomingValue, addresses) = internalTransactions.reduce(into: (value: BigUInt(0), addresses: [EvmKit.Address]())) { acc, internalTransaction in
                    if internalTransaction.to == userAddress {
                        acc.value += internalTransaction.value
                        acc.addresses.append(internalTransaction.from)
                    }
                }
                if totalIncomingValue <= baseCoinValue {
                    spamAddresses.append(contentsOf: addresses.map { $0 })
                }

                let eip20Transfers = decoration.eventInstances.compactMap { $0 as? TransferEventInstance }
                for transfer in eip20Transfers {
                    let query = TokenQuery(blockchainType: blockchainType, tokenType: .eip20(address: transfer.contractAddress.hex))

                    var isSpam: Bool
                    if let minValue = coinsMap[transfer.contractAddress] {
                        isSpam = transfer.value <= minValue
                    } else if let _ = try? coinManager.token(query: query) {
                        isSpam = transfer.value == 0
                    } else {
                        isSpam = true // Unknown token is considered spam
                    }

                    if isSpam {
                        let counterpartyAddress = transfer.from == userAddress ? transfer.to : transfer.from
                        spamAddresses.append(counterpartyAddress)
                    } else {
                        return []
                    }
                }

                let eip721Transfers = decoration.eventInstances.compactMap { $0 as? Eip721TransferEventInstance }
                let eip1155Transfers = decoration.eventInstances.compactMap { $0 as? Eip1155TransferEventInstance }

                if !eip721Transfers.isEmpty || !eip1155Transfers.isEmpty {
                    return []
                }

                return spamAddresses
            }

        default: ()
        }

        return []
    }

    private func spamConfig(blockchainType: BlockchainType) -> SpamConfig {
        let tokens = coins.reduce(into: []) { result, coin in
            result.append(contentsOf: coin.tokens.filter { $0.blockchainType == blockchainType })
        }
        var baseCoinValue = BigUInt.zero
        let coinsMap = tokens.reduce(into: [EvmKit.Address: BigUInt]()) { result, token in
            guard let value = coinValueLimits[token.coin.uid] else {
                return
            }

            if case let .eip20(addressString) = token.type, let address = try? EvmKit.Address(hex: addressString) {
                result[address] = token.fractionalMonetaryValue(value: value)
            } else if case .native = token.type {
                baseCoinValue = token.fractionalMonetaryValue(value: value)
            }
        }

        return SpamConfig(baseCoinValue: baseCoinValue, coinsMap: coinsMap, blockchainType: blockchainType)
    }

    private func handleEvmKitCreated(evmKitManager: EvmKitManager?, blockchainType: BlockchainType) {
        guard let evmKitWrapper = evmKitManager?.evmKitWrapper, let currentAccount = evmKitManager?.currentAccount else {
            return
        }

        let spamConfig = spamConfig(blockchainType: blockchainType)
        evmKitWrapper.evmKit.allTransactionsPublisher
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink { [weak self] fullTransactions, _ in
                self?.handle(fullTransactions: fullTransactions, userAddress: evmKitWrapper.evmKit.address, spamConfig: spamConfig)
            }
            .store(in: &cancellables)

        sync(evmKit: evmKitWrapper.evmKit, account: currentAccount, spamConfig: spamConfig)
    }

    private func sync(evmKit: EvmKit.Kit, account: Account, spamConfig: SpamConfig) {
        let spamScanState = try? storage.find(blockchainTypeUid: spamConfig.blockchainType.uid, accountUid: account.id)
        let fullTransactions = evmKit.allTransactionsAfter(transactionHash: spamScanState?.lastTransactionHash)
        let lastTransactionHash = handle(fullTransactions: fullTransactions, userAddress: evmKit.address, spamConfig: spamConfig)

        if let lastTransactionHash {
            let spamScanState = SpamScanState(blockchainTypeUid: spamConfig.blockchainType.uid, accountUid: account.id, lastTransactionHash: lastTransactionHash)
            try? storage.save(spamScanState: spamScanState)
        }
    }

    private func handle(fullTransactions: [FullTransaction], userAddress: EvmKit.Address, spamConfig: SpamConfig) -> Data? {
        let spamAddresses = fullTransactions.reduce(into: [SpamAddress]()) { acc, fullTransaction in
            let spamAddresses = scanSpamAddresses(fullTransaction: fullTransaction, userAddress: userAddress, spamConfig: spamConfig)
            acc.append(contentsOf: spamAddresses.map {
                SpamAddress(transactionHash: fullTransaction.transaction.hash, address: Address(raw: $0.eip55.uppercased(), blockchainType: spamConfig.blockchainType))
            })
        }
        do {
            try storage.save(spamAddresses: spamAddresses)
        } catch {}

        let transactions = fullTransactions.map(\.transaction)
        let sortedTransactions = transactions.sorted { tx1, tx2 in
            if tx1.timestamp != tx2.timestamp { return tx1.timestamp > tx2.timestamp }
            if let index1 = tx1.transactionIndex, let index2 = tx2.transactionIndex, index1 != index2 {
                return index1 > index2
            }
            return tx1.hash > tx2.hash
        }
        return sortedTransactions.first?.hash
    }
}

extension SpamAddressManager {
    func subscribeToKitCreation(evmKitManager: EvmKitManager, blockchainType: BlockchainType) {
        subscribe(ConcurrentDispatchQueueScheduler(qos: .userInitiated), disposeBag, evmKitManager.evmKitCreatedObservable) { [weak self, weak evmKitManager] in
            self?.handleEvmKitCreated(evmKitManager: evmKitManager, blockchainType: blockchainType)
        }
    }

    func find(address: String) -> SpamAddress? {
        try? storage.find(address: address)
    }

    func isSpam(transactionHash: Data) -> Bool {
        (try? storage.isSpam(transactionHash: transactionHash)) ?? false
    }
}

extension SpamAddressManager {
    static func isSpam(appValues: [AppValue]) -> Bool {
        let stableCoinUids = ["tether", "usd-coin", "dai", "binance-usd", "binance-peg-busd", "stasis-eurs"]

        for appValue in appValues {
            let value = appValue.value

            switch appValue.kind {
            case let .token(token):
                if stableCoinUids.contains(token.coin.uid) {
                    if value > 0.01 {
                        return false
                    }
                } else if value > 0 {
                    return false
                }
            case let .coin(coin, _):
                if stableCoinUids.contains(coin.uid) {
                    if value > 0.01 {
                        return false
                    }
                } else if value > 0 {
                    return false
                }
            case .nft:
                if value > 0 {
                    return false
                }
            default: ()
            }
        }

        return true
    }
}

struct SpamConfig {
    let baseCoinValue: BigUInt
    let coinsMap: [EvmKit.Address: BigUInt]
    let blockchainType: BlockchainType
}
