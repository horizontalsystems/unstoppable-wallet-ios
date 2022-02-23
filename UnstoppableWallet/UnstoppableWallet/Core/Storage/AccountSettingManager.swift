import RxSwift
import RxRelay

class AccountSettingManager {
    private let storage: IAccountSettingRecordStorage

    init(storage: IAccountSettingRecordStorage) {
        self.storage = storage
    }

    private func evmSyncSourceKey(blockchain: EvmBlockchain) -> String {
        "evm-sync-source-\(blockchain.rawValue)"
    }

}

extension AccountSettingManager {

    func evmSyncSourceName(account: Account, blockchain: EvmBlockchain) -> String? {
        storage.accountSetting(accountId: account.id, key: evmSyncSourceKey(blockchain: blockchain))?.value
    }

    func save(evmSyncSourceName: String, account: Account, blockchain: EvmBlockchain) {
        let record = AccountSettingRecord(accountId: account.id, key: evmSyncSourceKey(blockchain: blockchain), value: evmSyncSourceName)
        storage.save(accountSetting: record)
    }

}
