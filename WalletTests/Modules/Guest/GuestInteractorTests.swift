import XCTest
import Cuckoo
@testable import Wallet

class GuestInteractorTests: XCTestCase {

    var interactor: GuestInteractor!
    private var mockRouter: MockGuestRouterProtocol!

    override func setUp() {
        super.setUp()

        mockRouter = MockGuestRouterProtocol()
        interactor = GuestInteractor(router: mockRouter)
    }

    override func tearDown() {
        mockRouter = nil
        interactor = nil

        super.tearDown()
    }

    func testRoutesToCreateWallet() {
        stub(mockRouter) { mock in
            when(mock.showCreateWallet()).thenDoNothing()
        }

        interactor.createNewWalletDidTap()

        verify(mockRouter).showCreateWallet()
    }

    func testRoutesToRestoreWallet() {
        stub(mockRouter) { mock in
            when(mock.showRestoreWallet()).thenDoNothing()
        }

        interactor.restoreWalletDidTap()

        verify(mockRouter).showRestoreWallet()
    }

}
