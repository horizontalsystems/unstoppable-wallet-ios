import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class TransactionRateSyncerTests: XCTestCase {
    private var mockStorage: MockITransactionRecordStorage!
    private var mockNetworkManager: MockIRateNetworkManager!

    private var syncer: TransactionRateSyncer!

    private let bitcoin = "BTC"
    private let ether = "ETH"
    private let cash = "BCH"

    private let currencyCode = "USD"

    private let bitcoinHash = "Bitcoin Hash"
    private let etherHash = "Ether Hash"
    private let cashHash = "Cash Hash"

    private let bitcoinTimestamp = 1000
    private let etherTimestamp = 2000

    private let bitcoinValue: Double = 5000
    private let etherValue: Double = 300

    private var bitcoinRecord: TransactionRecord!
    private var etherRecord: TransactionRecord!
    private var cashRecord: TransactionRecord!

    override func setUp() {
        super.setUp()

        bitcoinRecord = TransactionRecord(transactionHash: bitcoinHash, coin: bitcoin, timestamp: bitcoinTimestamp)
        etherRecord = TransactionRecord(transactionHash: etherHash, coin: ether, timestamp: etherTimestamp)
        cashRecord = TransactionRecord(transactionHash: cashHash, coin: cash, timestamp: 0)

        mockStorage = MockITransactionRecordStorage()
        mockNetworkManager = MockIRateNetworkManager()

        stub(mockStorage) { mock in
            when(mock.nonFilledRecords.get).thenReturn([bitcoinRecord, etherRecord, cashRecord])
            when(mock.set(rate: any(), transactionHash: any())).thenDoNothing()
        }
        stub(mockNetworkManager) { mock in
            when(mock.getRate(coin: equal(to: bitcoin), currencyCode: equal(to: currencyCode), date: equal(to: Date(timeIntervalSince1970: Double(bitcoinTimestamp))))).thenReturn(Observable.just(bitcoinValue))
            when(mock.getRate(coin: equal(to: ether), currencyCode: equal(to: currencyCode), date: equal(to: Date(timeIntervalSince1970: Double(etherTimestamp))))).thenReturn(Observable.just(etherValue))
        }

        syncer = TransactionRateSyncer(storage: mockStorage, networkManager: mockNetworkManager, scheduler: MainScheduler.instance)
    }

    override func tearDown() {
        mockStorage = nil
        mockNetworkManager = nil

        syncer = nil

        super.tearDown()
    }

    func testSync() {
        syncer.sync(currencyCode: currencyCode)

        verify(mockStorage).set(rate: equal(to: bitcoinValue), transactionHash: equal(to: bitcoinHash))
        verify(mockStorage).set(rate: equal(to: etherValue), transactionHash: equal(to: etherHash))
        verify(mockStorage, never()).set(rate: any(), transactionHash: equal(to: cashHash))
    }

}
