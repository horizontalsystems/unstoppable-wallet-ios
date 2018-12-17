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

    private let bitcoinCurrentRate = LatestRate(value: 5000, timestamp: Date().timeIntervalSince1970)
    private let etherCurrentRate = LatestRate(value: 300, timestamp: Date().timeIntervalSince1970)

    override func setUp() {
        super.setUp()

        mockDelegate = MockIRateSyncerDelegate()
        mockNetworkManager = MockIRateNetworkManager()
        mockTimer = MockIPeriodicTimer()

        stub(mockNetworkManager) { mock in
            when(mock.getLatestRate(coinCode: equal(to: bitcoin), currencyCode: equal(to: currencyCode))).thenReturn(Observable.just(bitcoinCurrentRate))
            when(mock.getLatestRate(coinCode: equal(to: ether), currencyCode: equal(to: currencyCode))).thenReturn(Observable.just(etherCurrentRate))
        }
        stub(mockDelegate) { mock in
            when(mock.didSync(coinCode: any(), currencyCode: any(), latestRate: any())).thenDoNothing()
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

        verify(mockDelegate).didSync(coinCode: equal(to: bitcoin), currencyCode: equal(to: currencyCode), latestRate: equal(to: bitcoinCurrentRate))
        verify(mockDelegate).didSync(coinCode: equal(to: ether), currencyCode: equal(to: currencyCode), latestRate: equal(to: etherCurrentRate))
    }

    func testInvalidateTimerOnSync() {
        syncer.sync(coins: [bitcoin, ether], currencyCode: currencyCode)
        verify(mockTimer).schedule()
    }

}
