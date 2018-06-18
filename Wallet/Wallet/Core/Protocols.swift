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

protocol IUnspentOutputProvider {
    var unspentOutputs : [UnspentOutput] { get }
    var subject: PublishSubject<[UnspentOutput]> { get }
}

protocol IExchangeRateProvider {
    func getExchangeRate(forCoin coin: Coin) -> Double
    var subject: PublishSubject<[String: Double]> { get }
}

protocol IRandomProvider {
    func getRandomIndexes(count: Int) -> [Int]
}
