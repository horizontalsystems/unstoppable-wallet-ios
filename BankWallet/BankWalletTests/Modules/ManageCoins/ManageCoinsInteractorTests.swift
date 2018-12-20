import XCTest
import Cuckoo
@testable import Bank_Dev_T


class ManageCoinsInteractorTests: XCTestCase {
    private var mockDelegate: MockIManageCoinsInteractorDelegate!

    private var interactor: ManageCoinsInteractor!

    private var bitcoin: Coin!
    private var bitcoinCash: Coin!
    private var ethereum: Coin!

    private var allCoins: [Coin]!
    private var enabledCoins: [Coin]!
    private var disabledCoins: [Coin]!

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

        stub(mockDelegate) { mock in
//            when(mock.showCoins(enabled: any(), disabled: any())).thenDoNothing()
        }

        interactor = ManageCoinsInteractor()
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil

        interactor = nil

        super.tearDown()
    }

}
