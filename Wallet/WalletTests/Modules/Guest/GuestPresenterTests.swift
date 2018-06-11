import XCTest
import Cuckoo
@testable import Wallet

class GuestPresenterTests: XCTestCase {

    private var mockDelegate: MockGuestPresenterDelegate!
    private var mockRouter: MockGuestRouterProtocol!
    private var presenter: GuestPresenter!

    override func setUp() {
        super.setUp()

        mockDelegate = MockGuestPresenterDelegate()
        mockRouter = MockGuestRouterProtocol()
        presenter = GuestPresenter(delegate: mockDelegate, router: mockRouter)

        stub(mockDelegate) { mock in
            when(mock.createWallet()).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.showBackupRoutingToMain()).thenDoNothing()
            when(mock.showRestoreWallet()).thenDoNothing()
        }
    }

    override func tearDown() {
        mockRouter = nil
        presenter = nil

        super.tearDown()
    }

    func testDelegatesCreateWallet() {
        presenter.createNewWalletDidTap()

        verify(mockDelegate).createWallet()
    }

    func testRoutesToBackupOnCreateWallet() {
        presenter.didCreateWallet()

        verify(mockRouter).showBackupRoutingToMain()
    }

    func testRoutesToRestoreWallet() {
        presenter.restoreWalletDidTap()

        verify(mockRouter).showRestoreWallet()
    }

}
