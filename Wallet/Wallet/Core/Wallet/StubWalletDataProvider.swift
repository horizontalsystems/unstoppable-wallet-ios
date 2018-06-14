import Foundation

class StubWalletDataProvider: IWalletDataProvider {

    var walletData: WalletData {
        return WalletData(words: Factory.instance.userDefaultsStorage.savedWords ?? [])
    }

}
