import XCTest
import Cuckoo
@testable import Bank_Dev_T

class MainSettingsInteractorTests: XCTestCase {
    private var mockDelegate: MockIMainSettingsInteractorDelegate!

    private var mockLocalStorage: MockILocalStorage!
    private var mockWordsManager: MockIWordsManager!
    private var mockLanguageManager: MockILanguageManager!
    private var mockSystemInfoManager: MockISystemInfoManager!
    private var mockCurrencyManager: MockICurrencyManager!

    private var interactor: MainSettingsInteractor!

    private let backedUpSignal = Signal()
    private let baseCurrencyUpdatedSignal = Signal()

    override func setUp() {
        super.setUp()

        mockDelegate = MockIMainSettingsInteractorDelegate()

        mockLocalStorage = MockILocalStorage()
        mockWordsManager = MockIWordsManager()
        mockLanguageManager = MockILanguageManager()
        mockSystemInfoManager = MockISystemInfoManager()
        mockCurrencyManager = MockICurrencyManager()

        stub(mockWordsManager) { mock in
            when(mock.backedUpSignal.get).thenReturn(backedUpSignal)
        }
        stub(mockCurrencyManager) { mock in
            when(mock.baseCurrencyUpdatedSignal.get).thenReturn(baseCurrencyUpdatedSignal)
        }

        interactor = MainSettingsInteractor(localStorage: mockLocalStorage, wordsManager: mockWordsManager, languageManager: mockLanguageManager, systemInfoManager: mockSystemInfoManager, currencyManager: mockCurrencyManager, async: false)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil

        mockLocalStorage = nil
        mockWordsManager = nil
        mockLanguageManager = nil
        mockSystemInfoManager = nil
        mockCurrencyManager = nil

        interactor = nil

        super.tearDown()
    }

    func testIsBackedUp() {
        stub(mockWordsManager) { mock in
            when(mock.isBackedUp.get).thenReturn(true)
        }

        XCTAssertTrue(interactor.isBackedUp)
    }

    func testIsBackedUp_false() {
        stub(mockWordsManager) { mock in
            when(mock.isBackedUp.get).thenReturn(false)
        }

        XCTAssertFalse(interactor.isBackedUp)
    }

    func testCurrentLanguage() {
        let currentLanguageDisplayName = "Chitaurian"

        stub(mockLanguageManager) { mock in
            when(mock.displayNameForCurrentLanguage.get).thenReturn(currentLanguageDisplayName)
        }

        XCTAssertEqual(interactor.currentLanguage, currentLanguageDisplayName)
    }

    func testBaseCurrency() {
        let code = "USD"

        stub(mockCurrencyManager) { mock in
            when(mock.baseCurrency.get).thenReturn(Currency(code: "USD", symbol: ""))
        }

        XCTAssertEqual(interactor.baseCurrency, code)
    }

    func testLightMode_true() {
        stub(mockLocalStorage) { mock in
            when(mock.lightMode.get).thenReturn(true)
        }

        XCTAssertTrue(interactor.lightMode)
    }

    func testLightMode_false() {
        stub(mockLocalStorage) { mock in
            when(mock.lightMode.get).thenReturn(false)
        }

        XCTAssertFalse(interactor.lightMode)
    }

    func testAppVersion() {
        let appVersion = "1.0"

        stub(mockSystemInfoManager) { mock in
            when(mock.appVersion.get).thenReturn(appVersion)
        }

        XCTAssertEqual(interactor.appVersion, appVersion)
    }

    func testSetLightMode_true() {
        stub(mockLocalStorage) { mock in
            when(mock.lightMode.set(any())).thenDoNothing()
        }
        stub(mockDelegate) { mock in
            when(mock.didUpdateLightMode()).thenDoNothing()
        }

        interactor.set(lightMode: true)

        verify(mockLocalStorage).lightMode.set(true)
        verify(mockDelegate).didUpdateLightMode()
    }

    func testSetLightMode_false() {
        stub(mockLocalStorage) { mock in
            when(mock.lightMode.set(any())).thenDoNothing()
        }
        stub(mockDelegate) { mock in
            when(mock.didUpdateLightMode()).thenDoNothing()
        }

        interactor.set(lightMode: false)

        verify(mockLocalStorage).lightMode.set(false)
        verify(mockDelegate).didUpdateLightMode()
    }

    func testBackedUpSignal_true() {
        stub(mockWordsManager) { mock in
            when(mock.isBackedUp.get).thenReturn(true)
        }
        stub(mockDelegate) { mock in
            when(mock.didBackup()).thenDoNothing()
        }

        backedUpSignal.notify()

        verify(mockDelegate).didBackup()
    }

    func testBackedUpSignal_false() {
        stub(mockWordsManager) { mock in
            when(mock.isBackedUp.get).thenReturn(false)
        }

        backedUpSignal.notify()

        verify(mockDelegate, never()).didBackup()
    }

    func testBaseCurrencyUpdatedSignal() {
        stub(mockDelegate) { mock in
            when(mock.didUpdateBaseCurrency()).thenDoNothing()
        }

        baseCurrencyUpdatedSignal.notify()

        verify(mockDelegate).didUpdateBaseCurrency()
    }

}
