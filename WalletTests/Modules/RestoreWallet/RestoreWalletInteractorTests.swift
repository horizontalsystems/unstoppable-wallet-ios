import XCTest
import Cuckoo
@testable import Wallet

class RestoreWalletInteractorTests: XCTestCase {

    private var interactor: RestoreWalletInteractor!

    override func setUp() {
        super.setUp()

        interactor = RestoreWalletInteractor()
    }

    override func tearDown() {
        interactor = nil

        super.tearDown()
    }

//    func testClosesWhenCancelTapped() {
//        stub(mockRouter) { mock in
//            when(mock.close()).thenDoNothing()
//        }
//
//        interactor.cancelDidTap()
//
//        verify(mockRouter).close()
//    }

}
