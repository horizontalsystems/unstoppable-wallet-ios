import XCTest
import Cuckoo
@testable import Bank_Dev_T

class LanguageManagerTests: XCTestCase {
    private var mockLocalizationManager: MockILocalizationManager!
    private var mockLocalStorage: MockILocalStorage!

    private var manager: LanguageManager!

    private let currentLanguage = "ru"
    private let fallbackLanguage = "en"

    override func setUp() {
        super.setUp()

        mockLocalizationManager = MockILocalizationManager()
        mockLocalStorage = MockILocalStorage()

        stub(mockLocalStorage) { mock in
            when(mock.currentLanguage.get).thenReturn(currentLanguage)
            when(mock.currentLanguage.set(any())).thenDoNothing()
        }
        stub(mockLocalizationManager) { mock in
            when(mock.setLocale(forLanguage: any())).thenDoNothing()
        }

        manager = LanguageManager(localizationManager: mockLocalizationManager, localStorage: mockLocalStorage, fallbackLanguage: fallbackLanguage)
    }

    override func tearDown() {
        mockLocalizationManager = nil
        mockLocalStorage = nil

        manager = nil

        super.tearDown()
    }

    func testInitialLanguage_CurrentLanguage() {
        XCTAssertEqual(manager.currentLanguage, currentLanguage)
    }

    func testInitialLanguage_PreferredLanguage() {
        let preferredLanguage = "kg"

        stub(mockLocalStorage) { mock in
            when(mock.currentLanguage.get).thenReturn(nil)
        }
        stub(mockLocalizationManager) { mock in
            when(mock.preferredLanguage.get).thenReturn(preferredLanguage)
        }

        let manager = LanguageManager(localizationManager: mockLocalizationManager, localStorage: mockLocalStorage, fallbackLanguage: fallbackLanguage)

        XCTAssertEqual(manager.currentLanguage, preferredLanguage)
    }

    func testInitialLanguage_FallbackLanguage() {
        stub(mockLocalStorage) { mock in
            when(mock.currentLanguage.get).thenReturn(nil)
        }
        stub(mockLocalizationManager) { mock in
            when(mock.preferredLanguage.get).thenReturn(nil)
        }

        let manager = LanguageManager(localizationManager: mockLocalizationManager, localStorage: mockLocalStorage, fallbackLanguage: fallbackLanguage)

        XCTAssertEqual(manager.currentLanguage, fallbackLanguage)
    }

    func testDisplayNameForCurrentLanguage() {
        let displayName = "Русский"

        stub(mockLocalizationManager) { mock in
            when(mock.displayName(forLanguage: currentLanguage, inLanguage: currentLanguage)).thenReturn(displayName)
        }

        XCTAssertEqual(manager.displayNameForCurrentLanguage, displayName)
    }

    func testLocalizeString() {
        let string = "String"
        let localizedString = "LocalizedString"

        stub(mockLocalizationManager) { mock in
            when(mock.localize(string: string, language: currentLanguage)).thenReturn(localizedString)
        }

        XCTAssertEqual(manager.localize(string: string), localizedString)
    }

    func testLocalizeString_WithFallback() {
        let string = "String"
        let localizedString = "LocalizedString"

        stub(mockLocalizationManager) { mock in
            when(mock.localize(string: string, language: currentLanguage)).thenReturn(nil)
            when(mock.localize(string: string, language: fallbackLanguage)).thenReturn(localizedString)
        }

        XCTAssertEqual(manager.localize(string: string), localizedString)
    }

    func testLocalizeString_WithoutFallback() {
        let string = "String"

        stub(mockLocalizationManager) { mock in
            when(mock.localize(string: string, language: currentLanguage)).thenReturn(nil)
            when(mock.localize(string: string, language: fallbackLanguage)).thenReturn(nil)
        }

        XCTAssertEqual(manager.localize(string: string), string)
    }

    func testSetCurrentLanguage() {
        let newLanguage = "uz"

        manager.currentLanguage = newLanguage

        verify(mockLocalStorage).currentLanguage.set(equal(to: newLanguage))
        XCTAssertEqual(manager.currentLanguage, newLanguage)
    }

}
