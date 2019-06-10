import XCTest
import RxSwift
import Cuckoo
@testable import Bank_Dev_T

class GuestInteractorTests: XCTestCase {
    private var mockDelegate: MockIGuestInteractorDelegate!
    private var mockAuthManager: MockIAuthManager!
    private var mockWordsManager: MockIWordsManager!
    private var mockSystemInfoManager: MockISystemInfoManager!

    private var interactor: GuestInteractor!

    override func setUp() {
        super.setUp()

        mockDelegate = MockIGuestInteractorDelegate()
        mockAuthManager = MockIAuthManager()
        mockWordsManager = MockIWordsManager()
        mockSystemInfoManager = MockISystemInfoManager()

        stub(mockDelegate) { mock in
            when(mock.didCreateWallet()).thenDoNothing()
        }
        stub(mockAuthManager) { mock in
            when(mock.login(withWords: any(), syncMode: any())).thenDoNothing()
        }
        stub(mockWordsManager) { mock in
            when(mock.generateWords()).thenReturn([])
        }

        interactor = GuestInteractor(authManager: mockAuthManager, wordsManager: mockWordsManager, systemInfoManager: mockSystemInfoManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockAuthManager = nil
        mockWordsManager = nil
        mockSystemInfoManager = nil

        interactor = nil

        super.tearDown()
    }

    func testCreateWallet_success() {
        let expectedWords = ["one", "two"]

        stub(mockWordsManager) { mock in
            when(mock.generateWords()).thenReturn(expectedWords)
        }

        interactor.createWallet()

        verify(mockAuthManager).login(withWords: equal(to: expectedWords), syncMode: equal(to: SyncMode.new))
        verify(mockDelegate).didCreateWallet()
    }

    func testCreateWallet_failWords() {
        struct TestError: Error, Equatable {
            public static func ==(lhs: TestError, rhs: TestError) -> Bool {
                return true
            }
        }

        let error = TestError()

        stub(mockWordsManager) { mock in
            when(mock.generateWords()).thenThrow(error)
        }
        stub(mockDelegate) { mock in
            when(mock.didFailToCreateWallet(withError: any())).thenDoNothing()
        }

        interactor.createWallet()

        verify(mockDelegate).didFailToCreateWallet(withError: any())
    }

    func testAppVersion() {
        let appVersion = "1.0"

        stub(mockSystemInfoManager) { mock in
            when(mock.appVersion.get).thenReturn(appVersion)
        }

        XCTAssertEqual(interactor.appVersion, appVersion)
    }

}
