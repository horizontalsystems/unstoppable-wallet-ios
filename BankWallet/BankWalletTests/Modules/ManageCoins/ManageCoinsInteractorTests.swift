import XCTest
import Cuckoo
import RxSwift
@testable import Bank_Dev_T


class ManageCoinsInteractorTests: XCTestCase {
    private var mockDelegate: MockIManageCoinsInteractorDelegate!
    private var mockCoinManager: MockICoinManager!
    private var mockStorage: MockICoinStorage!

    private var interactor: ManageCoinsInteractor!

    private var bitcoin: Coin!
    private var bitcoinCash: Coin!
    private var ethereum: Coin!

    private var allCoins: [Coin]!
    private var enabledCoins: [Coin]!
    private var disabledCoins: [Coin]!

    private var coinsObservable = PublishSubject<[Coin]>()

    override func setUp() {
        super.setUp()
        bitcoin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
        bitcoinCash = Coin(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash)
        ethereum = Coin(title: "Ethereum", code: "ETH", type: .ethereum)
        allCoins = [
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


        mockDelegate = MockIManageCoinsInteractorDelegate()
        mockCoinManager = MockICoinManager()
        mockStorage = MockICoinStorage()

        stub(mockDelegate) { mock in
            when(mock.didLoad(allCoins: any())).thenDoNothing()
            when(mock.didLoad(enabledCoins: any())).thenDoNothing()
            when(mock.didSaveCoins()).thenDoNothing()
        }
        stub(mockCoinManager) { mock in
            when(mock.allCoins.get).thenReturn(allCoins)
        }
        stub(mockStorage) { mock in
            when(mock.enabledCoinsObservable()).thenReturn(coinsObservable)
            when(mock.save(enabledCoins: any())).thenDoNothing()
        }

        interactor = ManageCoinsInteractor(coinManager: mockCoinManager, storage: mockStorage, async: false)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockCoinManager = nil
        mockStorage = nil

        interactor = nil

        super.tearDown()
    }

    func testLoadAllCoins() {
        interactor.loadCoins()

        coinsObservable.onNext(allCoins)
        verify(mockDelegate).didLoad(allCoins: equal(to: allCoins))
    }

    func testLoadEnabledCoins() {
        interactor.loadCoins()

        coinsObservable.onNext(enabledCoins)
        verify(mockDelegate).didLoad(enabledCoins: equal(to: enabledCoins))
    }

    func testSaveCoins() {
        interactor.save(enabledCoins: enabledCoins)

        verify(mockStorage).save(enabledCoins: equal(to: enabledCoins))
        verify(mockDelegate).didSaveCoins()
    }

}
