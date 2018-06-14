import Foundation
import RxSwift

protocol WalletDataProviderProtocol {
    var walletData: WalletData { get }
}

protocol LocalStorageProtocol {
    var savedWords: [String]? { get }
    func save(words: [String])
}

protocol MnemonicProtocol {
    func generateWords() -> [String]
    func validate(words: [String]) -> Bool
}

protocol SettingsProtocol {
    var currency: Currency { get }
}

protocol UnspentOutputProviderProtocol {
//    var outputsSubject: PublishSubject<[UnspentOutput]> { get }
//    var fetchOutputsObservable: Observable<[UnspentOutput]> { get }
    func fetchUnspentOutputs(disposeBag: DisposeBag)
}

protocol UnspentOutputProviderDelegate {
    func didFetch(unspentOutputs: [UnspentOutput])
}
