import Foundation

class StubWalletDataProvider: WalletDataProviderProtocol {

    let walletData = WalletData(words: Factory.instance.mnemonicManager.generateWords())

}
