import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class DepositPresenterTests: XCTestCase {
    private var mockRouter: MockIDepositRouter!
    private var mockInteractor: MockIDepositInteractor!
    private var mockView: MockIDepositView!

    private var presenter: DepositPresenter!

    private let bitcoin = "BTC"
    private let ether = "ETH"

    private let bitcoinTitle = "Bitcoin"
    private let etherTitle = "Ethereum"

    private let bitcoinAddress = "bitcoin_address"
    private let etherAddress = "ether_address"

    private var mockBitcoinAdapter: MockIAdapter!
    private var mockEtherAdapter: MockIAdapter!

    override func setUp() {
        super.setUp()

        mockBitcoinAdapter = MockIAdapter()
        mockEtherAdapter = MockIAdapter()

        mockRouter = MockIDepositRouter()
        mockInteractor = MockIDepositInteractor()
        mockView = MockIDepositView()

        stub(mockRouter) { mock in
            when(mock.share(address: any())).thenDoNothing()
        }
        stub(mockView) { mock in
            when(mock.showCopied()).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.adapters(forCoin: equal(to: nil))).thenReturn([mockBitcoinAdapter, mockEtherAdapter])
            when(mock.copy(address: any())).thenDoNothing()
        }

        stub(mockBitcoinAdapter) { mock in
            when(mock.coin.get).thenReturn(Coin(title: bitcoinTitle, code: bitcoin, type: .bitcoin))
            when(mock.receiveAddress.get).thenReturn(bitcoinAddress)
        }
        stub(mockEtherAdapter) { mock in
            when(mock.coin.get).thenReturn(Coin(title: etherTitle, code: ether, type: .ethereum))
            when(mock.receiveAddress.get).thenReturn(etherAddress)
        }

        presenter = DepositPresenter(interactor: mockInteractor, router: mockRouter)
        presenter.view = mockView
    }

    override func tearDown() {
        mockRouter = nil
        mockInteractor = nil
        mockView = nil

        presenter = nil

        super.tearDown()
    }

    func testGetAddressItems() {
        let expectedItems = [
            AddressItem(coin: Coin(title: bitcoinTitle, code: bitcoin, type: .bitcoin), address: bitcoinAddress),
            AddressItem(coin: Coin(title: etherTitle, code: ether, type: .ethereum), address: etherAddress)
        ]

        XCTAssertEqual(presenter.addressItems(forCoin: nil), expectedItems)
    }

    func testOnCopy() {
        presenter.onCopy(addressItem: AddressItem(coin: Coin(title: bitcoinTitle, code: bitcoin, type: .bitcoin), address: bitcoinAddress))

        verify(mockInteractor).copy(address: equal(to: bitcoinAddress))
        verify(mockView).showCopied()
    }

    func testOnShare() {
        presenter.onShare(addressItem: AddressItem(coin: Coin(title: bitcoinTitle, code: bitcoin, type: .bitcoin), address: bitcoinAddress))

        verify(mockRouter).share(address: equal(to: bitcoinAddress))
    }

}
