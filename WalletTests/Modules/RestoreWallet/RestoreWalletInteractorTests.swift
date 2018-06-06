import XCTest
import Cuckoo
@testable import Wallet

class RestoreWalletInteractorTests: XCTestCase {

    private var mockRouter: MockRestoreWalletRouter!
    private var mockPresenter: MockRestoreWalletPresenterProtocol!
    private var interactor: RestoreWalletInteractor!

    override func setUp() {
        super.setUp()

        mockRouter = MockRestoreWalletRouter()
        mockPresenter = MockRestoreWalletPresenterProtocol()
        interactor = RestoreWalletInteractor(router: mockRouter, presenter: mockPresenter)
    }

    override func tearDown() {
        mockRouter = nil
        mockPresenter = nil
        interactor = nil

        super.tearDown()
    }

    func testClosesWhenCancelTapped() {
        stub(mockRouter) { mock in
            when(mock.close()).thenDoNothing()
        }

        interactor.cancelDidTap()

        verify(mockRouter).close()
    }

}
