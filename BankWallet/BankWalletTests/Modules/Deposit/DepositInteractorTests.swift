import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class DepositInteractorTests: XCTestCase {
    private var mockDelegate: MockIDepositInteractorDelegate!
    private var mockWalletManager: MockIWalletManager!
    private var mockPasteboardManager: MockIPasteboardManager!

    private var interactor: DepositInteractor!

    private let bitcoin = "BTC"
    private let ether = "ETH"

    private var bitcoinWallet: Wallet!
    private var etherWallet: Wallet!

    override func setUp() {
        super.setUp()

        bitcoinWallet = Wallet(coinCode: bitcoin, adapter: MockIAdapter())
        etherWallet = Wallet(coinCode: ether, adapter: MockIAdapter())

        mockDelegate = MockIDepositInteractorDelegate()
        mockWalletManager = MockIWalletManager()
        mockPasteboardManager = MockIPasteboardManager()

        stub(mockWalletManager) { mock in
            when(mock.wallets.get).thenReturn([bitcoinWallet, etherWallet])
        }
        stub(mockPasteboardManager) { mock in
            when(mock.set(value: any())).thenDoNothing()
        }

        interactor = DepositInteractor(walletManager: mockWalletManager, pasteboardManager: mockPasteboardManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockWalletManager = nil
        mockPasteboardManager = nil

        interactor = nil

        super.tearDown()
    }

    func testWalletsForCoin_AllCoins() {
        let wallets = interactor.wallets(forCoin: nil)

        XCTAssertEqual(wallets.count, 2)
        XCTAssertTrue(wallets[0] === bitcoinWallet)
        XCTAssertTrue(wallets[1] === etherWallet)
    }

    func testWalletsForCoin_DefiniteCoin() {
        let wallets = interactor.wallets(forCoin: ether)

        XCTAssertEqual(wallets.count, 1)
        XCTAssertTrue(wallets[0] === etherWallet)
    }

    func testCopyAddress() {
        let address = "some_address"

        interactor.copy(address: address)

        verify(mockPasteboardManager).set(value: equal(to: address))
    }

}
