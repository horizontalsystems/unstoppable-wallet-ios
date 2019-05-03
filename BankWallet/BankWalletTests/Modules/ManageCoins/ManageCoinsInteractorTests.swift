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

    private var enabledCoinsObservable: BehaviorSubject<[Coin]>!

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

        enabledCoinsObservable = BehaviorSubject(value: enabledCoins)

        mockDelegate = MockIManageCoinsInteractorDelegate()
        mockCoinManager = MockICoinManager()
        mockStorage = MockICoinStorage()

        stub(mockDelegate) { mock in
            when(mock.didLoad(allCoins: any(), enabledCoins: any())).thenDoNothing()
            when(mock.didSaveCoins()).thenDoNothing()
        }
        stub(mockCoinManager) { mock in
            when(mock.allCoins.get).thenReturn(allCoins)
        }
        stub(mockStorage) { mock in
            when(mock.enabledCoinsObservable()).thenReturn(enabledCoinsObservable)
            when(mock.save(enabledCoins: any())).thenDoNothing()
        }

        interactor = ManageCoinsInteractor(coinManager: mockCoinManager, storage: mockStorage)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockCoinManager = nil
        mockStorage = nil

        interactor = nil

        super.tearDown()
    }

    func testLoadCoins() {
        interactor.loadCoins()

        verify(mockDelegate).didLoad(allCoins: equal(to: allCoins), enabledCoins: equal(to: enabledCoins))
    }

    func testSaveCoins() {
        interactor.save(enabledCoins: enabledCoins)

        verify(mockStorage).save(enabledCoins: equal(to: enabledCoins))
        verify(mockDelegate).didSaveCoins()
    }

}
