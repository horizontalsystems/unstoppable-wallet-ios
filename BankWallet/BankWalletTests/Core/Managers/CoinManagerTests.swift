import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class CoinManagerTests: XCTestCase {
    private var mockStorage: MockIEnabledCoinStorage!
    private var mockAppConfigProvider: MockIAppConfigProvider!

    private var manager: WalletManager!

    private let bitcoin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
    private let bitcoinCash: Coin = Coin(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash)
    private let ethereum: Coin = Coin(title: "Ethereum", code: "ETH", type: .ethereum)

    private var enabledCoinsObservable = PublishSubject<[EnabledWallet]>()

    override func setUp() {
        super.setUp()

        mockStorage = MockIEnabledCoinStorage()
        mockAppConfigProvider = MockIAppConfigProvider()

        stub(mockStorage) { mock in
            when(mock.enabledCoinsObservable.get).thenReturn(enabledCoinsObservable)
        }

        manager = WalletManager(appConfigProvider: mockAppConfigProvider, storage: mockStorage)
    }

    override func tearDown() {
        mockStorage = nil
        mockAppConfigProvider = nil

        manager = nil

        super.tearDown()
    }

    func testAllCoins() {
        let allCoins = [bitcoin, bitcoinCash, ethereum]

        stub(mockAppConfigProvider) { mock in
            when(mock.coins.get).thenReturn(allCoins)
        }

        XCTAssertEqual(manager.allCoins, allCoins)
    }

    func testInitialSetEnabledCoins() {
        let defaultCoinCodes = [bitcoin.code, ethereum.code]
        let enabledCoins = [
            EnabledCoin(coinCode: bitcoin.code, order: 0),
            EnabledCoin(coinCode: ethereum.code, order: 1)
        ]

        stub(mockAppConfigProvider) { mock in
            when(mock.defaultCoinCodes.get).thenReturn(defaultCoinCodes)
        }
        stub(mockStorage) { mock in
            when(mock.save(enabledCoins: any())).thenDoNothing()
        }

        manager.enableDefaultWallets()

        verify(mockStorage).save(enabledCoins: equal(to: enabledCoins))
    }

    func testUpdateEnabledCoins() {
        let allCoins = [bitcoin, bitcoinCash, ethereum]
        let enabledCoins = [
            EnabledCoin(coinCode: bitcoin.code, order: 0),
            EnabledCoin(coinCode: ethereum.code, order: 1)
        ]

        stub(mockAppConfigProvider) { mock in
            when(mock.coins.get).thenReturn(allCoins)
        }

        let expectations = expectation(description: "signal_notify")

        _ = manager.walletsUpdatedSignal.subscribe(onNext: {
            expectations.fulfill()
        })

        enabledCoinsObservable.onNext(enabledCoins)

        waitForExpectations(timeout: 2)
        XCTAssertEqual(manager.wallets, [bitcoin, ethereum])
    }

    func testClear() {
        stub(mockStorage) { mock in
            when(mock.clearEnabledCoins()).thenDoNothing()
        }

        manager.clear()

        XCTAssertTrue(manager.wallets.isEmpty)
        verify(mockStorage).clearEnabledCoins()
    }

}
