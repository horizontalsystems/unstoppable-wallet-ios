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
    func getBitcoinUnspentOutputs() -> Observable<DatabaseChangeSet<BitcoinUnspentOutput>>
    func getBitcoinCashUnspentOutputs() -> Observable<DatabaseChangeSet<BitcoinCashUnspentOutput>>
    func getExchangeRates() -> Observable<DatabaseChangeSet<ExchangeRate>>
    func getTransactionRecords() -> Observable<DatabaseChangeSet<TransactionRecord>>
    func getBlockchainInfos() -> Observable<DatabaseChangeSet<BlockchainInfo>>
}

protocol INetworkManager {
    func getJwtToken(identity: String, pubKeys: [Int: String]) -> Observable<String>
}

protocol SettingsProtocol {
    var currency: Currency { get }
}

protocol IRandomProvider {
    func getRandomIndexes(count: Int) -> [Int]
}
