//import XCTest
//import Cuckoo
//import RxSwift
//@testable import Unstoppable_Dev_T
//
//class ManageWalletsInteractorTests: XCTestCase {
//    private var mockDelegate: MockIManageCoinsInteractorDelegate!
//    private var mockCoinManager: MockICoinManager!
//    private var mockStorage: MockIEnabledCoinStorage!
//
//    private var interactor: ManageWalletsInteractor!
//
//    private let bitcoin = Coin(title: "Bitcoin", code: "BTC", type: .bitcoin)
//    private let bitcoinCash: Coin = Coin(title: "Bitcoin Cash", code: "BCH", type: .bitcoinCash)
//    private let ethereum: Coin = Coin(title: "Ethereum", code: "ETH", type: .ethereum)
//
//    override func setUp() {
//        super.setUp()
//
//        mockDelegate = MockIManageCoinsInteractorDelegate()
//        mockCoinManager = MockICoinManager()
//        mockStorage = MockIEnabledCoinStorage()
//
//        interactor = ManageWalletsInteractor(coinManager: mockCoinManager, storage: mockStorage)
//        interactor.delegate = mockDelegate
//    }
//
//    override func tearDown() {
//        mockDelegate = nil
//        mockCoinManager = nil
//        mockStorage = nil
//
//        interactor = nil
//
//        super.tearDown()
//    }
//
//    func testLoadCoins() {
//        let allCoins = [bitcoin, bitcoinCash, ethereum]
//        let enabledCoins = [
//            EnabledCoin(coinCode: bitcoin.code, order: 0),
//            EnabledCoin(coinCode: ethereum.code, order: 1)
//        ]
//        let enabledCoinsObservable = BehaviorSubject<[EnabledWallet]>(value: enabledCoins)
//
//        stub(mockCoinManager) { mock in
//            when(mock.allCoins.get).thenReturn(allCoins)
//        }
//        stub(mockStorage) { mock in
//            when(mock.enabledCoinsObservable.get).thenReturn(enabledCoinsObservable)
//        }
//        stub(mockDelegate) { mock in
//            when(mock.didLoad(allCoins: any(), enabledCoins: any())).thenDoNothing()
//        }
//
//        interactor.load()
//
//        verify(mockDelegate).didLoad(allCoins: equal(to: allCoins), enabledCoins: equal(to: [bitcoin, ethereum]))
//    }
//
//    func testSaveCoins() {
//        let coins = [bitcoinCash, ethereum]
//        let enabledCoins = [
//            EnabledCoin(coinCode: bitcoinCash.code, order: 0),
//            EnabledCoin(coinCode: ethereum.code, order: 1)
//        ]
//
//        stub(mockDelegate) { mock in
//            when(mock.didSaveCoins()).thenDoNothing()
//        }
//        stub(mockStorage) { mock in
//            when(mock.save(enabledCoins: any())).thenDoNothing()
//        }
//
//        interactor.save(enabledCoins: coins)
//
//        verify(mockStorage).save(enabledCoins: equal(to: enabledCoins))
//        verify(mockDelegate).didSaveCoins()
//    }
//
//}
