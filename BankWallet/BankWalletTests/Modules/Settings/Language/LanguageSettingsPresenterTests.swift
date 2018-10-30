import XCTest
import Cuckoo
@testable import Bank_Dev_T

class LanguageSettingsPresenterTests: XCTestCase {
    private var mockRouter: MockILanguageSettingsRouter!
    private var mockInteractor: MockILanguageSettingsInteractor!
    private var mockView: MockILanguageSettingsView!

    private var presenter: LanguageSettingsPresenter!

    private let items = [
        LanguageItem(id: "en", title: "English", subtitle: "English", current: true),
        LanguageItem(id: "ru", title: "Russian", subtitle: "Русский", current: false)
    ]

    override func setUp() {
        super.setUp()

        mockRouter = MockILanguageSettingsRouter()
        mockInteractor = MockILanguageSettingsInteractor()
        mockView = MockILanguageSettingsView()

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.show(items: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.reloadAppInterface()).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.items.get).thenReturn(items)
            when(mock.setCurrentLanguage(with: any())).thenDoNothing()
        }

        presenter = LanguageSettingsPresenter(router: mockRouter, interactor: mockInteractor)
        presenter.view = mockView
    }

    override func tearDown() {
        mockRouter = nil
        mockInteractor = nil
        mockView = nil

        presenter = nil

        super.tearDown()
    }

    func testShowTitle() {
        presenter.viewDidLoad()
        verify(mockView).set(title: "settings_language.title")
    }

    func testShowItemsOnLoad() {
        presenter.viewDidLoad()
        verify(mockView).show(items: equal(to: items))
    }

    func testDidSelectLanguageItem() {
        let item = items[1]
        presenter.didSelect(item: item)
        verify(mockInteractor).setCurrentLanguage(with: equal(to: item))
    }

    func testDidSetCurrentLanguage() {
        presenter.didSetCurrentLanguage()
        verify(mockRouter).reloadAppInterface()
    }

}
