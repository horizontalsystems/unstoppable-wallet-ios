import Foundation
import RxSwift
import BitcoinKit

class StubUnspentOutputProvider: UnspentOutputProviderProtocol {
//    let disposeBag = DisposeBag()

    let unspentOutputsSubject = PublishSubject<[UnspentOutput]>()

    func fetchUnspentOutputs(disposeBag: DisposeBag) {
        let seed = Mnemonic.seed(mnemonic: Factory.instance.stubWalletDataProvider.walletData.words, passphrase: "")

        let hdWallet = HDWallet(seed: seed, network: Network.testnet)

        var addresses = [String]()

        for i in 0...20 {
            if let address = try? hdWallet.receiveAddress(index: UInt32(i)) {
                print(String(describing: address))
                addresses.append(String(describing: address))
            }
        }

        for i in 0...20 {
            if let address = try? hdWallet.changeAddress(index: UInt32(i)) {
                addresses.append(String(describing: address))
            }
        }

        NetworkManager.instance.unspentOutputs(forAddresses: addresses).subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] unspentOutputs in
            self?.unspentOutputsSubject.onNext(unspentOutputs)
        })
    }

}
