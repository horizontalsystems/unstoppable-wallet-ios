import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class CoinManagerTests: XCTestCase {
    private var mockStorage: MockICoinStorage!
    private var mockAppConfigProvider: MockIAppConfigProvider!

    private var manager: CoinManager!

    private var bitcoin: Coin!
    private var bitcoinCash: Coin!
    private var ethereum: Coin!

    private var defaultCoins: [Coin]!
    private var enabledCoins: [Coin]!
    private var disabledCoins: [Coin]!

    private var coinsObservable = PublishSubject<[Coin]>()

    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        mockStorage = MockICoinStorage()
        mockAppConfigProvider = MockIAppConfigProvider()
        mockStorage = MockICoinStorage()
        disposeBag = DisposeBag()

        bitcoin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
        bitcoinCash = Coin(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash)
        ethereum = Coin(title: "Ethereum", code: "ETH", type: .ethereum)
        defaultCoins = [
            bitcoin,
            bitcoinCash,
            ethereum
        ]
        enabledCoins = [
            bitcoin,
            ethereum
        ]
        disabledCoins = [
            bitcoinCash,
        ]

        stub(mockAppConfigProvider) { mock in
            when(mock.defaultCoins.get).thenReturn(defaultCoins)
        }
        stub(mockStorage) { mock in
            when(mock.allCoinsObservable()).thenReturn(coinsObservable)
            when(mock.enabledCoinsObservable()).thenReturn(coinsObservable)
            when(mock.save(enabledCoins: any())).thenDoNothing()
        }

        manager = CoinManager(appConfigProvider: mockAppConfigProvider, storage: mockStorage, async: false)
    }

    override func tearDown() {
        mockStorage = nil
        mockAppConfigProvider = nil
        mockStorage = nil
        disposeBag = nil

        manager = nil

        super.tearDown()
    }

    func testInitialSetEnabledCoins() {
        manager.enableDefaultCoins()
        verify(mockStorage).save(enabledCoins: equal(to: defaultCoins))
    }

    func testAllCoins() {
        let defaultCoins = self.defaultCoins
        manager.allCoinsObservable.subscribe(onNext: {
            XCTAssertEqual(defaultCoins, $0)
        }).disposed(by: disposeBag)

        coinsObservable.onNext([])
    }

    func testUpdateSignal() {
        let expectations = expectation(description: "signal_notify")
        manager.coinsUpdatedSignal.subscribe(onNext: {
            expectations.fulfill()
        }).disposed(by: disposeBag)
        coinsObservable.onNext([])
        waitForExpectations(timeout: 2)
    }

}
