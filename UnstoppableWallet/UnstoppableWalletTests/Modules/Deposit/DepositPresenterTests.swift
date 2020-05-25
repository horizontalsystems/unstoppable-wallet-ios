//import XCTest
//import RxSwift
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class DepositPresenterTests: XCTestCase {
//    private var mockRouter: MockIDepositRouter!
//    private var mockInteractor: MockIDepositInteractor!
//    private var mockView: MockIDepositView!
//
//    private var presenter: DepositPresenter!
//
//    private let bitcoin = Coin.mock(title: "Bitcoin", code: "BTC", type: .bitcoin)
//    private let ethereum = Coin.mock(title: "Ethereum", code: "ETH", type: .ethereum)
//
//    private let bitcoinAddress = "bitcoin_address"
//    private let ethereumAddress = "ether_address"
//
//    private var mockBitcoinAdapter: MockIAdapter!
//    private var mockEtherAdapter: MockIAdapter!
//
//    override func setUp() {
//        super.setUp()
//
//        mockBitcoinAdapter = MockIAdapter()
//        mockEtherAdapter = MockIAdapter()
//
//        mockRouter = MockIDepositRouter()
//        mockInteractor = MockIDepositInteractor()
//        mockView = MockIDepositView()
//
//        stub(mockRouter) { mock in
//            when(mock.share(address: any())).thenDoNothing()
//        }
//        stub(mockView) { mock in
//            when(mock.showCopied()).thenDoNothing()
//        }
//        stub(mockInteractor) { mock in
//            when(mock.adapters(forCoin: equal(to: nil))).thenReturn([mockBitcoinAdapter, mockEtherAdapter])
//            when(mock.copy(address: any())).thenDoNothing()
//        }
//
//        stub(mockBitcoinAdapter) { mock in
//            when(mock.wallet.get).thenReturn(Wallet.mock(coin: bitcoin))
//            when(mock.receiveAddress.get).thenReturn(bitcoinAddress)
//        }
//        stub(mockEtherAdapter) { mock in
//            when(mock.wallet.get).thenReturn(Wallet.mock(coin: ethereum))
//            when(mock.receiveAddress.get).thenReturn(ethereumAddress)
//        }
//
//        presenter = DepositPresenter(interactor: mockInteractor, router: mockRouter, coin: nil)
//        presenter.view = mockView
//    }
//
//    override func tearDown() {
//        mockRouter = nil
//        mockInteractor = nil
//        mockView = nil
//
//        presenter = nil
//
//        super.tearDown()
//    }
//
//    func testGetAddressItems() {
//        let expectedItems = [
//            AddressItem(coin: bitcoin, address: bitcoinAddress),
//            AddressItem(coin: ethereum, address: ethereumAddress)
//        ]
//
//        XCTAssertEqual(presenter.addressItems, expectedItems)
//    }
//
//    func testOnCopy() {
//        presenter.onCopy(index: 1)
//
//        verify(mockInteractor).copy(address: equal(to: ethereumAddress))
//        verify(mockView).showCopied()
//    }
//
//    func testOnShare() {
//        presenter.onShare(index: 1)
//
//        verify(mockRouter).share(address: equal(to: ethereumAddress))
//    }
//
//}
