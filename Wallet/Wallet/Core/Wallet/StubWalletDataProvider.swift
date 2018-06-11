import Foundation

class StubWalletDataProvider: WalletDataProviderProtocol {

    var walletData: WalletData {
        return WalletData(words: Factory.instance.userDefaultsStorage.savedWords ?? [])
    }

}
