//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class FullTransactionInfoRouterTests: XCTestCase {
//
//    private var router: FullTransactionInfoRouter!
//    private var mockUrlManager: MockIUrlManager!
//    private var url: String!
//    private var controller: UINavigationController!
//
//    override func setUp() {
//        super.setUp()
//
//        url = "test_url"
//        controller = UINavigationController()
//        mockUrlManager = MockIUrlManager()
//        stub(mockUrlManager) { mock in
//            when(mock.open(url: any(), from: any())).thenDoNothing()
//        }
//
//        router = FullTransactionInfoRouter(urlManager: mockUrlManager)
//        router.viewController = controller
//    }
//
//    override func tearDown() {
//        url = nil
//        controller = nil
//        mockUrlManager = nil
//
//        router = nil
//
//        super.tearDown()
//    }
//
//    func testOpenUrl() {
//        router.open(url: url)
//
//        verify(mockUrlManager).open(url: equal(to: url), from: equal(to: controller))
//    }
//
//}
