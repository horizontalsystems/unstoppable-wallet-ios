//import XCTest
//import Cuckoo
//import RxSwift
//@testable import Unstoppable_Dev_T
//
//class DataProviderSettingsInteractorTests: XCTestCase {
//    private var mockDelegate: MockIDataProviderSettingsInteractorDelegate!
//    private var mockDataProviderManager: MockIFullTransactionDataProviderManager!
//    private var mockPingManager: MockIPingManager!
//
//    private var interactor: DataProviderSettingsInteractor!
//
//    private let coin = Coin.mock(title: "Bitcoin", code: "BTC", type: .bitcoin)
//    private let firstName = "first_provider"
//    private let secondName = "second_provider"
//
//    private var firstProvider: MockIProvider!
//    private var secondProvider: MockIProvider!
//    private var providers: [IProvider]!
//
//    override func setUp() {
//        super.setUp()
//
//        firstProvider = MockIProvider()
//        stub(firstProvider) { mock in
//            when(mock.name.get).thenReturn(firstName)
//        }
//        secondProvider = MockIProvider()
//        stub(secondProvider) { mock in
//            when(mock.name.get).thenReturn(secondName)
//        }
//        providers = [firstProvider, secondProvider]
//
//        mockDelegate = MockIDataProviderSettingsInteractorDelegate()
//        mockDataProviderManager = MockIFullTransactionDataProviderManager()
//
//        stub(mockDelegate) { mock in
//            when(mock.didSetBaseProvider()).thenDoNothing()
//            when(mock.didPingFailure(name: any())).thenDoNothing()
//            when(mock.didPingSuccess(name: any(), timeInterval: any())).thenDoNothing()
//        }
//        stub(mockDataProviderManager) { mock in
//            when(mock.providers(for: any())).thenReturn(providers)
//            when(mock.baseProvider(for: any())).thenReturn(firstProvider)
//            when(mock.setBaseProvider(name: any(), for: any())).thenDoNothing()
//        }
//        mockPingManager = MockIPingManager()
//        interactor = DataProviderSettingsInteractor(dataProviderManager: mockDataProviderManager, pingManager: mockPingManager, async: false)
//        interactor.delegate = mockDelegate
//    }
//
//    override func tearDown() {
//        mockDelegate = nil
//        mockDataProviderManager = nil
//
//        interactor = nil
//
//        super.tearDown()
//    }
//
//    func testPingProviderSuccess() {
//        stub(mockPingManager) { mock in
//            when(mock.serverAvailable(url: any(), timeoutInterval: any())).thenReturn(Observable.just(1.0))
//        }
//        interactor.pingProvider(name: "test_name", url: "test_url")
//
//        waitForMainQueue()
//        verify(mockPingManager).serverAvailable(url: "test_url", timeoutInterval: any())
//        verify(mockDelegate).didPingSuccess(name: "test_name", timeInterval: 1.0)
//    }
//
//    func testPingProviderError() {
//        stub(mockPingManager) { mock in
//            when(mock.serverAvailable(url: any(), timeoutInterval: any())).thenReturn(Observable.error(PingManagerError.responseFailure))
//        }
//        interactor.pingProvider(name: "test_name", url: "test_url")
//
//        waitForMainQueue()
//        verify(mockPingManager).serverAvailable(url: "test_url", timeoutInterval: any())
//        verify(mockDelegate).didPingFailure(name: "test_name")
//    }
//
//    func testGetProviders() {
//        XCTAssertEqual(interactor.providers(for: coin).map { $0.name }, providers.map { $0.name })
//    }
//
//    func testGetBaseProvider() {
//        XCTAssertEqual(interactor.baseProvider(for: coin).name, firstName)
//    }
//
//    func testSetBaseCurrency() {
//        interactor.setBaseProvider(name: firstName, for: coin)
//
//        verify(mockDataProviderManager).setBaseProvider(name: equal(to: firstName), for: equal(to: coin))
//        verify(mockDelegate).didSetBaseProvider()
//    }
//
//}
