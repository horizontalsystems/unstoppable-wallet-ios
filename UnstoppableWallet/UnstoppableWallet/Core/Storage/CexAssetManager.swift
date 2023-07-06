import RxSwift
import MarketKit

class CexAssetManager {
    private let accountManager: AccountManager
    private let marketKit: MarketKit.Kit
    private let storage: CexAssetRecordStorage
    private let disposeBag = DisposeBag()

    init(accountManager: AccountManager, marketKit: MarketKit.Kit, storage: CexAssetRecordStorage) {
        self.accountManager = accountManager
        self.marketKit = marketKit
        self.storage = storage

        subscribe(disposeBag, accountManager.accountDeletedObservable) { [weak self] account in
            try? self?.storage.clear(accountId: account.id)
        }
    }

    private func mapped(records: [CexAssetRecord]) throws -> [CexAsset] {
        let coins = try marketKit.allCoins()
        var coinMap = [String: Coin]()
        coins.forEach { coinMap[$0.uid] = $0 }

        let blockchains = try marketKit.allBlockchains()
        var blockchainMap = [String: Blockchain]()
        blockchains.forEach { blockchainMap[$0.uid] = $0 }

        return records.compactMap { record in
            CexAsset(
                    id: record.id,
                    name: record.name,
                    freeBalance: record.freeBalance,
                    lockedBalance: record.lockedBalance,
                    depositEnabled: record.depositEnabled,
                    withdrawEnabled: record.withdrawEnabled,
                    depositNetworks: record.depositNetworks.map { $0.cexDepositNetwork(blockchain: $0.blockchainUid.flatMap { blockchainMap[$0] }) },
                    withdrawNetworks: record.withdrawNetworks.map { $0.cexWithdrawNetwork(blockchain: $0.blockchainUid.flatMap { blockchainMap[$0] }) },
                    coin: record.coinUid.flatMap { coinMap[$0] }
            )
        }
    }

}

extension CexAssetManager {

    func balanceCexAssets(account: Account) -> [CexAsset] {
        do {
            let records = try storage.balanceAssets(accountId: account.id)
            return try mapped(records: records)
        } catch {
            print("Failed to fetch assets: \(error)")
            return []
        }
    }

    func cexAssets(account: Account) -> [CexAsset] {
        do {
            let records = try storage.assets(accountId: account.id)
            return try mapped(records: records)
        } catch {
            print("Failed to fetch assets: \(error)")
            return []
        }
    }

    func resave(cexAssetResponses: [CexAssetResponse], account: Account) {
        do {
            try storage.resave(records: cexAssetResponses.map { $0.record(accountId: account.id) }, accountId: account.id)
        } catch {
            print("Failed to resave: \(error)")
        }
    }

}
