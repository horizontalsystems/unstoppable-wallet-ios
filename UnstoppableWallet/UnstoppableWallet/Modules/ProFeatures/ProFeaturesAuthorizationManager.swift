import UIKit
import RxCocoa
import RxRelay
import RxSwift
import EthereumKit
import BigInt

//val contractAddress = Address("0x9940bb667F64fcA06fc4127861855696DeF7c69d")
//val tokenId = BigInteger("5391")
//val owner = Address("0xbf02ab1a188967505ab98101be083ffce9124dfe")

class ProFeaturesAuthorizationManager {
    static let contractAddress = try! EthereumKit.Address(hex: "0x9940bb667F64fcA06fc4127861855696DeF7c69d")
    static let owner = try! EthereumKit.Address(hex: "0xbf02ab1a188967505ab98101be083ffce9124dfe")
    static let tokenId = BigUInt(5391)

    private let accountManager: AccountManager
    private let storage: ProFeaturesStorage

    private let sessionKeyRelay = PublishRelay<SessionKey>()

    init(storage: ProFeaturesStorage, accountManager: AccountManager) {
        self.storage = storage
        self.accountManager = accountManager
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
                .enumerated()
                .compactMap { index, account in
                    //todo: Add temporary accountData
                    if accounts.count == index + 1 {
                        return AccountData(accountId: account.id, address: Self.owner)
                    }

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

    func sessionKey(type: ProFeaturesStorage.NFTType) -> String? {
        storage.get(type: type)?.sessionKey
    }

    func set(accountId: String, address: String, sessionKey: String, type: ProFeaturesStorage.NFTType) {
        storage.save(type: type, key: ProFeaturesStorage.SessionKey(accountId: accountId, address: address, sessionKey: sessionKey))
        sessionKeyRelay.accept(SessionKey(type: type, key: sessionKey))
    }

    func nftHolder(type: ProFeaturesStorage.NFTType) -> Single<AccountData?> {
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

}

extension ProFeaturesAuthorizationManager {

    struct AccountData {
        let accountId: String
        let address: EthereumKit.Address
    }

    struct SessionKey {
        let type: ProFeaturesStorage.NFTType
        let key: String
    }

}