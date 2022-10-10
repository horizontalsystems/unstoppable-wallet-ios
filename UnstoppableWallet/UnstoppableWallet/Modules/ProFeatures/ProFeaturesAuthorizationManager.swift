import UIKit
import RxCocoa
import RxRelay
import RxSwift
import EvmKit
import BigInt
import HsExtensions

class ProFeaturesAuthorizationManager {
    static let contractAddress = try! EvmKit.Address(hex: "0x495f947276749ce646f68ac8c248420045cb7b5e")
    static let tokenId = BigUInt("77929411300911548602579223184347481465604416464327802926072149574722519040001", radix: 10)!

    private let disposeBag = DisposeBag()

    private let accountManager: AccountManager
    private let storage: ProFeaturesStorage
    private let evmSyncSourceManager: EvmSyncSourceManager

    private let sessionKeyRelay = PublishRelay<SessionKey>()

    init(storage: ProFeaturesStorage, accountManager: AccountManager, evmSyncSourceManager: EvmSyncSourceManager) {
        self.storage = storage
        self.accountManager = accountManager
        self.evmSyncSourceManager = evmSyncSourceManager

        subscribe(disposeBag, accountManager.accountDeletedObservable) { [weak self] in self?.sync(deletedAccount: $0) }
    }

    private func sync(deletedAccount: Account) {
        storage.delete(accountId: deletedAccount.id)
    }

    private func sortedAccountData() -> [AccountData] {
        let accounts = accountManager
                .accounts
                .filter { account in
                    account.type.mnemonicSeed != nil
                }

        guard !accounts.isEmpty,
              let active = accountManager.activeAccount
        else {

            return []
        }

        return accounts
                .sorted { account, account2 in
                    account.id == active.id
                }
                .compactMap { account in
                    if let seed = account.type.mnemonicSeed,
                       let address = try? Signer.address(seed: seed, chain: .ethereum) {
                        return AccountData(accountId: account.id, address: address)
                    }
                    return nil
                }
    }

    private func tokenHolder(provider: Eip1155Provider, contractAddress: EvmKit.Address, tokenId: BigUInt, accountData: [AccountData], index: Int = 0) -> Single<AccountData?> {
        guard accountData.count > index else {
            return Single.just(nil)
        }

        return provider.getBalanceOf(contractAddress: contractAddress, tokenId: tokenId, address: accountData[index].address)
                .flatMap { [weak self] balance in
                    if balance != 0 {
                        return Single.just(accountData[index])
                    } else {
                        return self?.tokenHolder(provider: provider, contractAddress: contractAddress, tokenId: tokenId, accountData: accountData, index: index + 1) ?? Single.just(nil)
                    }
                }
    }

}

extension ProFeaturesAuthorizationManager {

    var sessionKeyObservable: Observable<SessionKey> {
        sessionKeyRelay.asObservable()
    }

    func sessionKey(type: NftType) -> String? {
        storage.get(type: type)?.sessionKey
    }

    func set(accountId: String, address: String, sessionKey: String, type: NftType) {
        storage.save(type: type, key: ProFeaturesStorage.SessionKey(accountId: accountId, address: address, sessionKey: sessionKey))
        sessionKeyRelay.accept(SessionKey(type: type, key: sessionKey))
    }

    func nftHolder(type: NftType) -> Single<AccountData?> {
        let accountData = sortedAccountData()

        guard !accountData.isEmpty,
              let provider = try? Eip1155Provider.instance(rpcSource: evmSyncSourceManager.infuraRpcSource) else {

            return Single.just(nil)
        }

        return tokenHolder(provider: provider, contractAddress: Self.contractAddress, tokenId: Self.tokenId, accountData: accountData)
    }

    func sign(accountData: AccountData, data: Data) -> String? {
        guard let account = accountManager.account(id: accountData.accountId),
              let seed = account.type.mnemonicSeed else {
            return nil
        }

        let signatureData = try? EvmKit.Kit.sign(message: data, seed: seed)
        return signatureData.map { "0x\($0.hs.hex)" }
    }

    func clearSessionKey(type: NftType?) {
        storage.clear(type: type)
    }

}

extension ProFeaturesAuthorizationManager {

    enum NftType: String, CaseIterable {
        case mountainYak
    }

    struct AccountData {
        let accountId: String
        let address: EvmKit.Address
    }

    struct SessionKey {
        let type: NftType
        let key: String
    }

}
