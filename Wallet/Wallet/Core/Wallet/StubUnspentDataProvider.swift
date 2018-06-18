import Foundation
import RxSwift
import BitcoinKit

class StubUnspentOutputProvider: IUnspentOutputProvider {
    let subject = PublishSubject<[UnspentOutput]>()

    var unspentOutputs: [UnspentOutput] {
        return [
            UnspentOutput(value: 32500000, index: 0, confirmations: 0, transactionHash: "", script: ""),
            UnspentOutput(value: 16250000, index: 0, confirmations: 0, transactionHash: "", script: "")
        ]
    }

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: { [weak self] in
            self?.subject.onNext([
                UnspentOutput(value: 42500000, index: 0, confirmations: 0, transactionHash: "", script: ""),
                UnspentOutput(value: 26250000, index: 0, confirmations: 0, transactionHash: "", script: "")
            ])
        })
    }

    //    let disposeBag = DisposeBag()

//    let unspentOutputsSubject = PublishSubject<[UnspentOutput]>()

//    var unspentOutputsObservable: Observable<[UnspentOutput]> {
//        let seed = Mnemonic.seed(mnemonic: Factory.instance.stubWalletDataProvider.walletData.words, passphrase: "")
//
//        let hdWallet = HDWallet(seed: seed, network: Network.testnet)
//
//        var addresses = [String]()
//
//        for i in 0...20 {
//            if let address = try? hdWallet.receiveAddress(index: UInt32(i)) {
//                print(String(describing: address))
//                addresses.append(String(describing: address))
//            }
//        }
//
//        for i in 0...20 {
//            if let address = try? hdWallet.changeAddress(index: UInt32(i)) {
//                addresses.append(String(describing: address))
//            }
//        }
//
//        return NetworkManager.instance.unspentOutputs(forAddresses: addresses)
//    }

//    func fetchUnspentOutputs() {
//        let seed = Mnemonic.seed(mnemonic: Factory.instance.stubWalletDataProvider.walletData.words, passphrase: "")
//
//        let hdWallet = HDWallet(seed: seed, network: Network.testnet)
//
//        var addresses = [String]()
//
//        for i in 0...20 {
//            if let address = try? hdWallet.receiveAddress(index: UInt32(i)) {
//                print(String(describing: address))
//                addresses.append(String(describing: address))
//            }
//        }
//
//        for i in 0...20 {
//            if let address = try? hdWallet.changeAddress(index: UInt32(i)) {
//                addresses.append(String(describing: address))
//            }
//        }
//
//        NetworkManager.instance.unspentOutputs(forAddresses: addresses).subscribeAsync(disposeBag: disposeBag, onNext: { [weak self] unspentOutputs in
//            self?.unspentOutputsSubject.onNext(unspentOutputs)
//        })
//    }

}
