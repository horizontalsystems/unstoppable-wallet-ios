import UIKit
import RxCocoa
import RxRelay
import RxSwift
import EthereumKit

class ProFeaturesAuthorizationManager {
    private let accountManager: AccountManager
    private let storage: ProFeaturesStorage

    private let sessionKeyRelay = PublishRelay<SessionKey>()

    init(storage: ProFeaturesStorage, accountManager: AccountManager) {
        self.storage = storage
        self.accountManager = accountManager
    }

}

extension ProFeaturesAuthorizationManager {

    var sessionKeyObservable: Observable<SessionKey> {
        sessionKeyRelay.asObservable()
    }

    func sessionKey(type: ProFeaturesStorage.NFTType) -> String? {
        storage.get(type: type)?.sessionKey
    }

    var allAccountData: [AccountData] {
        accountManager.accounts.compactMap { account in
            switch account.type {
            case .privateKey(data: data):
                let address = Signer.address(privateKey: data)
                return address.map { AccountData(accountId: account.id, address: $0) }
            case .mnemonic:
                guard let seed = account.type.mnemonicSeed else {
                    return nil
                }
                let address = try? Signer.address(seed: seed, chain: .ethereum)
                return address.map { AccountData(accountId: account.id, address: $0) }
            default: return nil
            }
        }
    }

}

extension ProFeaturesAuthorizationManager {

    struct AccountData {
        let accountId: String
        let address: String
    }

    struct SessionKey {
        let type: ProFeaturesStorage.NFTType
        let key: String
    }

}