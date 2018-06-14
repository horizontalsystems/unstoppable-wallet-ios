import Foundation
import RxSwift

protocol IWalletDataProvider {
    var walletData: WalletData { get }
}

protocol ILocalStorage {
    var savedWords: [String]? { get }
    func save(words: [String])
}

protocol IMnemonic {
    func generateWords() -> [String]
    func validate(words: [String]) -> Bool
}

protocol SettingsProtocol {
    var currency: Currency { get }
}

protocol UnspentOutputProviderProtocol {
//    var outputsSubject: PublishSubject<[UnspentOutput]> { get }
//    var fetchOutputsObservable: Observable<[UnspentOutput]> { get }
    func fetchUnspentOutputs()
}

protocol UnspentOutputProviderDelegate {
    func didFetch(unspentOutputs: [UnspentOutput])
}

protocol IRandomProvider {
    func getRandomIndexes(count: Int) -> [Int]
}
