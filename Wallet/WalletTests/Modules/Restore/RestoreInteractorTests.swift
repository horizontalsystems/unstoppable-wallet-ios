import XCTest
import Cuckoo
@testable import Wallet

class RestoreInteractorTests: XCTestCase {

    private var interactor: RestoreInteractor!

    override func setUp() {
        super.setUp()

        interactor = RestoreInteractor()
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
