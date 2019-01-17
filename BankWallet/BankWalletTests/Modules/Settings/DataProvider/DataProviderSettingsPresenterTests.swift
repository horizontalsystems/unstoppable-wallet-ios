import XCTest
import Cuckoo
@testable import Bank_Dev_T

class DataProviderSettingsPresenterTests: XCTestCase {
    private var mockRouter: MockIDataProviderSettingsRouter!
    private var mockInteractor: MockIDataProviderSettingsInteractor!
    private var mockView: MockIDataProviderSettingsView!

    private var presenter: DataProviderSettingsPresenter!

    private let coinCode = "coin_code"
    private let firstName = "first_provider"
    private let secondName = "second_provider"

    private var firstProvider: MockIProvider!
    private var secondProvider: MockIProvider!
    private var providers: [IProvider]!

    private var expectedItems: [DataProviderItem]!

    override func setUp() {
        super.setUp()

        firstProvider = MockIProvider()
        stub(firstProvider) { mock in
            when(mock.name.get).thenReturn(firstName)
        }
        secondProvider = MockIProvider()
        stub(secondProvider) { mock in
            when(mock.name.get).thenReturn(secondName)
        }
        providers = [firstProvider, secondProvider]

        expectedItems = [
            DataProviderItem(name: firstName, online: true, selected: true),
            DataProviderItem(name: secondName, online: true, selected: false)
        ]

        mockRouter = MockIDataProviderSettingsRouter()
        mockInteractor = MockIDataProviderSettingsInteractor()
        mockView = MockIDataProviderSettingsView()

        stub(mockView) { mock in
            when(mock.show(items: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
        }
        stub(mockInteractor) { mock in
            when(mock.providers(for: any())).thenReturn(providers)
            when(mock.baseProvider(for: any())).thenReturn(firstProvider)
            when(mock.setBaseProvider(name: any(), for: any())).thenDoNothing()
        }

        presenter = DataProviderSettingsPresenter(coinCode: coinCode, router: mockRouter, interactor: mockInteractor)
        presenter.view = mockView
    }

    override func tearDown() {
        mockRouter = nil
        mockInteractor = nil
        mockView = nil

        presenter = nil

        super.tearDown()
    }

    func testShowItemsOnLoad() {
        presenter.viewDidLoad()
        verify(mockView).show(items: equal(to: expectedItems))
    }

    func testSelectItem() {
        presenter.didSelect(item: DataProviderItem(name: secondName, online: true, selected: false))
        verify(mockInteractor).setBaseProvider(name: equal(to: secondName), for: equal(to: coinCode))
    }

    func testSelectItem_AlreadySelected() {
        presenter.didSelect(item: DataProviderItem(name: secondName, online: false, selected: true))
        verify(mockInteractor, never()).setBaseProvider(name: any(), for: any())
    }

    func testReloadItemsOnSetBaseCurrency() {
        presenter.didSetBaseProvider()
        verify(mockView).show(items: equal(to: expectedItems))
    }

}
