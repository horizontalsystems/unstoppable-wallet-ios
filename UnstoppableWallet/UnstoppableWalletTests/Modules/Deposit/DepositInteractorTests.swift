//import XCTest
//import RxSwift
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class DepositInteractorTests: XCTestCase {
//    private var mockDelegate: MockIDepositInteractorDelegate!
//    private var mockAdapterManager: MockIAdapterManager!
//    private var mockPasteboardManager: MockIPasteboardManager!
//
//    private var interactor: DepositInteractor!
//
//    private let bitcoin = Coin.mock(title: "Bitcoin", code: "BTC", type: .bitcoin)
//    private let ether = Coin.mock(title: "Ethereum", code: "ETH", type: .ethereum)
//
//    private let mockBitcoinAdapter = MockIAdapter()
//    private let mockEtherAdapter = MockIAdapter()
//
//    override func setUp() {
//        super.setUp()
//
//        mockDelegate = MockIDepositInteractorDelegate()
//        mockAdapterManager = MockIAdapterManager()
//        mockPasteboardManager = MockIPasteboardManager()
//
//        stub(mockBitcoinAdapter) { mock in
//            when(mock.wallet.get).thenReturn(Wallet.mock(coin: bitcoin))
//        }
//        stub(mockEtherAdapter) { mock in
//            when(mock.wallet.get).thenReturn(Wallet.mock(coin: ether))
//        }
//        stub(mockAdapterManager) { mock in
//            when(mock.adapters.get).thenReturn([mockBitcoinAdapter, mockEtherAdapter])
//        }
//        stub(mockPasteboardManager) { mock in
//            when(mock.set(value: any())).thenDoNothing()
//        }
//
//        interactor = DepositInteractor(adapterManager: mockAdapterManager, pasteboardManager: mockPasteboardManager)
//        interactor.delegate = mockDelegate
//    }
//
//    override func tearDown() {
//        mockDelegate = nil
//        mockAdapterManager = nil
//        mockPasteboardManager = nil
//
//        interactor = nil
//
//        super.tearDown()
//    }
//
//    func testWalletsForCoin_AllCoins() {
//        let adapters = interactor.wallets(forCoin: nil)
//
//        XCTAssertEqual(adapters.count, 2)
//        XCTAssertTrue(adapters[0] === mockBitcoinAdapter)
//        XCTAssertTrue(adapters[1] === mockEtherAdapter)
//    }
//
//    func testWalletsForCoin_DefiniteCoin() {
//        let adapters = interactor.wallets(forCoin: ether)
//
//        XCTAssertEqual(adapters.count, 1)
//        XCTAssertTrue(adapters[0] === mockEtherAdapter)
//    }
//
//    func testCopyAddress() {
//        let address = "some_address"
//
//        interactor.copy(address: address)
//
//        verify(mockPasteboardManager).set(value: equal(to: address))
//    }
//
//}
