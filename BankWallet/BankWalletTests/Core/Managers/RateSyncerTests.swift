import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class RateSyncerTests: XCTestCase {
    private var mockDelegate: MockIRateSyncerDelegate!
    private var mockNetworkManager: MockIRateNetworkManager!
    private var mockTimer: MockIPeriodicTimer!

    private var syncer: RateSyncer!

    private let bitcoin = "BTC"
    private let ether = "ETH"

    private let currencyCode = "USD"

    private let bitcoinValue: Double = 5000
    private let etherValue: Double = 300

    override func setUp() {
        super.setUp()

        mockDelegate = MockIRateSyncerDelegate()
        mockNetworkManager = MockIRateNetworkManager()
        mockTimer = MockIPeriodicTimer()

        stub(mockNetworkManager) { mock in
            when(mock.getLatestRate(coin: equal(to: bitcoin), currencyCode: equal(to: currencyCode))).thenReturn(Observable.just(bitcoinValue))
            when(mock.getLatestRate(coin: equal(to: ether), currencyCode: equal(to: currencyCode))).thenReturn(Observable.just(etherValue))
        }
        stub(mockDelegate) { mock in
            when(mock.didSync(coin: any(), currencyCode: any(), value: any())).thenDoNothing()
        }
        stub(mockTimer) { mock in
            when(mock.schedule()).thenDoNothing()
        }

        syncer = RateSyncer(networkManager: mockNetworkManager, timer: mockTimer, async: false)
        syncer.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockNetworkManager = nil
        mockTimer = nil

        syncer = nil

        super.tearDown()
    }

    func testSync() {
        syncer.sync(coins: [bitcoin, ether], currencyCode: currencyCode)

        verify(mockDelegate).didSync(coin: equal(to: bitcoin), currencyCode: equal(to: currencyCode), value: equal(to: bitcoinValue))
        verify(mockDelegate).didSync(coin: equal(to: ether), currencyCode: equal(to: currencyCode), value: equal(to: etherValue))
    }

    func testInvalidateTimerOnSync() {
        syncer.sync(coins: [bitcoin, ether], currencyCode: currencyCode)
        verify(mockTimer).schedule()
    }

}
