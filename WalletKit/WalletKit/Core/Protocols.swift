import Foundation
import RxSwift

protocol ILocalStorage: class {
    var savedWords: [String]? { get }
    func save(words: [String])
    func clearWords()
}

public protocol IDatabaseManager {
    //    func getBitcoinUnspentOutputs() -> Observable<DatabaseChangeSet<BitcoinUnspentOutput>>
    //    func getBitcoinCashUnspentOutputs() -> Observable<DatabaseChangeSet<BitcoinCashUnspentOutput>>
    func getBalances() -> Observable<DatabaseChangeSet<Balance>>
    func getExchangeRates() -> Observable<DatabaseChangeSet<ExchangeRate>>
    func getTransactionRecords() -> Observable<DatabaseChangeSet<TransactionRecord>>
//    func getBlockchainInfos() -> Observable<DatabaseChangeSet<BlockchainInfo>>
}
