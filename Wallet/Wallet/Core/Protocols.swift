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

protocol IDatabaseManager {
    func getUnspentOutputs() -> [UnspentOutput]
    func insert(unspentOutputs: [UnspentOutput])
    func truncateUnspentOutputs()

    func getExchangeRates() -> [String: Double]
    func insert(exchangeRates: [String: Double])
    func truncateExchangeRates()
}

protocol INetworkManager {
    func getUnspentOutputs() -> Observable<[UnspentOutput]>
    func getExchangeRates() -> Observable<[String: Double]>
}

protocol SettingsProtocol {
    var currency: Currency { get }
}

protocol IRandomProvider {
    func getRandomIndexes(count: Int) -> [Int]
}
