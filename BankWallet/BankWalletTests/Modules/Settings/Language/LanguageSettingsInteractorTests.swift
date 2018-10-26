import XCTest
import Cuckoo
@testable import Bank_Dev_T

class LanguageSettingsInteractorTests: XCTestCase {
    private var mockDelegate: MockILanguageSettingsInteractorDelegate!
    private var mockLanguageManager: MockILanguageManager!
    private var mockLocalizationManager: MockILocalizationManager!

    private var interactor: LanguageSettingsInteractor!

    private let items = [
        LanguageItem(id: "en", title: "English", subtitle: "English", current: true),
        LanguageItem(id: "ru", title: "Russian", subtitle: "Русский", current: false)
    ]

    override func setUp() {
        super.setUp()

        mockDelegate = MockILanguageSettingsInteractorDelegate()
        mockLanguageManager = MockILanguageManager()
        mockLocalizationManager = MockILocalizationManager()

        stub(mockDelegate) { mock in
            when(mock.didSetCurrentLanguage()).thenDoNothing()
        }
        stub(mockLanguageManager) { mock in
            when(mock.currentLanguage.get).thenReturn(items[0].id)
            when(mock.currentLanguage.set(any())).thenDoNothing()
        }
        stub(mockLocalizationManager) { mock in
            when(mock.availableLanguages.get).thenReturn(items.map { $0.id })

            let currentItem = items[0]

            for item in items {
                when(mock.displayName(forLanguage: item.id, inLanguage: currentItem.id)).thenReturn(item.title)
                when(mock.displayName(forLanguage: item.id, inLanguage: item.id)).thenReturn(item.subtitle)
            }
        }

        interactor = LanguageSettingsInteractor(languageManager: mockLanguageManager, localizationManager: mockLocalizationManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockLanguageManager = nil
        mockLocalizationManager = nil

        interactor = nil

        super.tearDown()
    }

    func testGetItems() {
        XCTAssertEqual(interactor.items, items)
    }

    func testSetCurrentLanguage() {
        let item = items[1]

        interactor.setCurrentLanguage(with: item)

        verify(mockLanguageManager).currentLanguage.set(item.id)
        verify(mockDelegate).didSetCurrentLanguage()
    }

}
