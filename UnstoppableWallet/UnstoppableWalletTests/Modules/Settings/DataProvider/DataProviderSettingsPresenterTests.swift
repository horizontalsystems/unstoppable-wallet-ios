//import XCTest
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class DataProviderSettingsPresenterTests: XCTestCase {
//    private var mockRouter: MockIDataProviderSettingsRouter!
//    private var mockInteractor: MockIDataProviderSettingsInteractor!
//    private var mockView: MockIDataProviderSettingsView!
//
//    private var presenter: DataProviderSettingsPresenter!
//
//    private let coin = Coin.mock(title: "Bitcoin", code: "BTC", type: .bitcoin)
//    private let firstName = "first_provider"
//    private let secondName = "second_provider"
//    private let txHash = "tx_hash"
//
//    private var firstProvider: MockIProvider!
//    private var secondProvider: MockIProvider!
//    private var providers: [IProvider]!
//
//    private var expectedItems: [DataProviderItem]!
//
//    override func setUp() {
//        super.setUp()
//
//        firstProvider = MockIProvider()
//        stub(firstProvider) { mock in
//            when(mock.name.get).thenReturn(firstName)
//            when(mock.requestObject(for: any())).thenReturn(JsonApiProvider.RequestObject.get(url: "first_url", params: nil))
//            when(mock.reachabilityUrl(for: any())).thenReturn("first_url")
//        }
//        secondProvider = MockIProvider()
//        stub(secondProvider) { mock in
//            when(mock.name.get).thenReturn(secondName)
//            when(mock.requestObject(for: any())).thenReturn(JsonApiProvider.RequestObject.get(url: "second_url", params: nil))
//            when(mock.reachabilityUrl(for: any())).thenReturn("second_url")
//        }
//        providers = [firstProvider, secondProvider]
//
//        expectedItems = [
//            DataProviderItem(name: firstName, online: true, checking: true, selected: true),
//            DataProviderItem(name: secondName, online: true, checking: true, selected: false)
//        ]
//
//        mockRouter = MockIDataProviderSettingsRouter()
//        mockInteractor = MockIDataProviderSettingsInteractor()
//        mockView = MockIDataProviderSettingsView()
//
//        stub(mockView) { mock in
//            when(mock.show(items: any())).thenDoNothing()
//        }
//        stub(mockRouter) { mock in
//            when(mock.popViewController()).thenDoNothing()
//        }
//        stub(mockInteractor) { mock in
//            when(mock.providers(for: any())).thenReturn(providers)
//            when(mock.baseProvider(for: any())).thenReturn(firstProvider)
//            when(mock.setBaseProvider(name: any(), for: any())).thenDoNothing()
//            when(mock.pingProvider(name: any(), url: any())).thenDoNothing()
//        }
//
//        presenter = DataProviderSettingsPresenter(coin: coin, transactionHash: txHash, router: mockRouter, interactor: mockInteractor)
//        presenter.view = mockView
//    }
//
//    override func tearDown() {
//        mockRouter = nil
//        mockInteractor = nil
//        mockView = nil
//
//        presenter = nil
//
//        super.tearDown()
//    }
//
//    func testShowItemsOnLoad() {
//        presenter.viewDidLoad()
//        verify(mockInteractor).pingProvider(name: firstName, url: "first_url")
//        verify(mockInteractor).pingProvider(name: secondName, url: "second_url")
//        XCTAssertEqual(presenter.items, expectedItems)
//        verify(mockView).show(items: equal(to: expectedItems))
//    }
//
//    func testSelectItem() {
//        presenter.didSelect(item: DataProviderItem(name: secondName, online: true, checking: false, selected: false))
//        verify(mockInteractor).setBaseProvider(name: equal(to: secondName), for: equal(to: coin))
//    }
//
//    func testSelectItem_AlreadySelected() {
//        presenter.didSelect(item: DataProviderItem(name: secondName, online: false, checking: false, selected: true))
//        verify(mockInteractor, never()).setBaseProvider(name: any(), for: any())
//    }
//
//    func testReloadItemsOnSetBaseCurrency() {
//        presenter.didSetBaseProvider()
//        verify(mockRouter).popViewController()
//    }
//
//    func testDidPingSuccess() {
//        let items = [
//            DataProviderItem(name: firstName, online: false, checking: true, selected: true)
//        ]
//        presenter.items = items
//        presenter.didPingSuccess(name: firstName, timeInterval: 1)
//
//        XCTAssertEqual(presenter.items, [DataProviderItem(name: firstName, online: true, checking: false, selected: true)])
//        verify(mockView).show(items: equal(to: [DataProviderItem(name: firstName, online: true, checking: false, selected: true)]))
//    }
//
//    func testDidPingFailure() {
//        let items = [
//            DataProviderItem(name: firstName, online: true, checking: true, selected: true)
//        ]
//        presenter.items = items
//        presenter.didPingFailure(name: firstName)
//
//        XCTAssertEqual(presenter.items, [DataProviderItem(name: firstName, online: false, checking: false, selected: true)])
//        verify(mockView).show(items: equal(to: [DataProviderItem(name: firstName, online: false, checking: false, selected: true)]))
//    }
//
//    func testDidPingWrongName() {
//        let items = [
//            DataProviderItem(name: firstName, online: true, checking: true, selected: true)
//        ]
//        presenter.items = items
//        presenter.didPingFailure(name: "wrong_name")
//
//        XCTAssertNotEqual(presenter.items, [DataProviderItem(name: "wrong_name", online: false, checking: false, selected: true)])
//        verify(mockView, never()).show(items: any())
//    }
//
//}
