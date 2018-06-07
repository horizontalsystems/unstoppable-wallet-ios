import XCTest
import Cuckoo
@testable import Wallet

class GuestPresenterTests: XCTestCase {

    private var mockRouter: MockGuestRouterProtocol!
    private var presenter: GuestPresenter!

    override func setUp() {
        super.setUp()

        mockRouter = MockGuestRouterProtocol()
        presenter = GuestPresenter(router: mockRouter)

        stub(mockRouter) { mock in
            when(mock.showBackupWallet()).thenDoNothing()
            when(mock.showRestoreWallet()).thenDoNothing()
        }
    }

    override func tearDown() {
        mockRouter = nil
        presenter = nil

        super.tearDown()
    }

    func testRoutesToBackupWallet() {
        presenter.createNewWalletDidTap()

        verify(mockRouter).showBackupWallet()
    }

    func testRoutesToRestoreWallet() {
        presenter.restoreWalletDidTap()

        verify(mockRouter).showRestoreWallet()
    }

}
