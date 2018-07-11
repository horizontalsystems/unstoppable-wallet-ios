import Foundation
import RxSwift

protocol IDatabaseManager {
//    func getBitcoinUnspentOutputs() -> Observable<DatabaseChangeSet<BitcoinUnspentOutput>>
//    func getBitcoinCashUnspentOutputs() -> Observable<DatabaseChangeSet<BitcoinCashUnspentOutput>>
    func getBalances() -> Observable<DatabaseChangeSet<Balance>>
    func getExchangeRates() -> Observable<DatabaseChangeSet<ExchangeRate>>
    func getTransactionRecords() -> Observable<DatabaseChangeSet<TransactionRecord>>
    func getBlockchainInfos() -> Observable<DatabaseChangeSet<BlockchainInfo>>
}

protocol IRandomProvider {
    func getRandomIndexes(count: Int) -> [Int]
}
