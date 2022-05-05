import UIKit
import RxCocoa
import RxRelay
import RxSwift
import EthereumKit
import BigInt

class ProFeaturesAuthorizationManager {
    static let contractAddress = try! EthereumKit.Address(hex: "0x495f947276749ce646f68ac8c248420045cb7b5e")
    static let tokenId = BigUInt("77929411300911548602579223184347481465604416464327802926072149574722519040001", radix: 10)!

    private let disposeBag = DisposeBag()

    private let accountManager: AccountManager
    private let storage: ProFeaturesStorage

    private let sessionKeyRelay = PublishRelay<SessionKey>()

    init(storage: ProFeaturesStorage, accountManager: AccountManager) {
        self.storage = storage
        self.accountManager = accountManager

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

    private var balanceProvider: Eip1155Provider? {
        let evmKit = try? EvmKitManager.temporaryEvmKit()

        return evmKit.map {
            Eip1155Provider(evmKit: $0)
        }
    }

    private func tokenHolder(provider: Eip1155Provider, contractAddress: EthereumKit.Address, tokenId: BigUInt, accountData: [AccountData], index: Int = 0) -> Single<AccountData?> {
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

    func sessionKey(type: NFTType) -> String? {
        storage.get(type: type)?.sessionKey
    }

    func set(accountId: String, address: String, sessionKey: String, type: NFTType) {
        storage.save(type: type, key: ProFeaturesStorage.SessionKey(accountId: accountId, address: address, sessionKey: sessionKey))
        sessionKeyRelay.accept(SessionKey(type: type, key: sessionKey))
    }

    func nftHolder(type: NFTType) -> Single<AccountData?> {
        let accountData = sortedAccountData()


        guard !accountData.isEmpty,
              let provider = balanceProvider else {

            return Single.just(nil)
        }

        return tokenHolder(provider: provider, contractAddress: Self.contractAddress, tokenId: Self.tokenId, accountData: accountData)
    }

    func sign(accountData: AccountData, data: Data) -> String? {
        guard let account = accountManager.account(id: accountData.accountId),
              let seed = account.type.mnemonicSeed else {
            return nil
        }

        let signatureData = try? EthereumKit.Kit.sign(message: data, seed: seed)
        return signatureData.map { "0x\($0.hex)" }
    }

    func clearSessionKey(type: NFTType?) {
        storage.clear(type: type)
    }

}

extension ProFeaturesAuthorizationManager {

    enum NFTType: String, CaseIterable {
        case mountainYak
    }

    struct AccountData {
        let accountId: String
        let address: EthereumKit.Address
    }

    struct SessionKey {
        let type: NFTType
        let key: String
    }

}
