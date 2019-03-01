import XCTest
import Cuckoo
@testable import Bank_Dev_T

class GuestPresenterTests: XCTestCase {
    private var mockRouter: MockIGuestRouter!
    private var mockInteractor: MockIGuestInteractor!
    private var mockView: MockIGuestView!

    private var presenter: GuestPresenter!

    override func setUp() {
        super.setUp()

        mockRouter = MockIGuestRouter()
        mockInteractor = MockIGuestInteractor()
        mockView = MockIGuestView()

        presenter = GuestPresenter(interactor: mockInteractor, router: mockRouter)
        presenter.view = mockView
    }

    override func tearDown() {
        mockRouter = nil
        mockInteractor = nil
        mockView = nil

        presenter = nil

        super.tearDown()
    }

    func testShowAppVersionOnLoad() {
        let appVersion = "1"

        stub(mockView) { mock in
            when(mock.set(appVersion: any())).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.appVersion.get).thenReturn(appVersion)
        }

        presenter.viewDidLoad()
        verify(mockView).set(appVersion: appVersion)
    }

    func testOpenBackup_createWallet() {
        stub(mockRouter) { mock in
            when(mock.navigateToBackupRoutingToMain()).thenDoNothing()
        }
        presenter.didCreateWallet()

        verify(mockRouter).navigateToBackupRoutingToMain()
    }

    func testCreateWallet() {
        stub(mockInteractor) { mock in
            when(mock.createWallet()).thenDoNothing()
        }
        presenter.createWalletDidClick()

        verify(mockInteractor).createWallet()
    }

    func testOpenRestore() {
        stub(mockRouter) { mock in
            when(mock.navigateToRestore()).thenDoNothing()
        }
        presenter.restoreWalletDidClick()

        verify(mockRouter).navigateToRestore()
    }

}
