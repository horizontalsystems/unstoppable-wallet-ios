import XCTest
import Cuckoo
import RxSwift
@testable import Bank_Dev_T

class MainSettingsInteractorTests: XCTestCase {
    private var mockDelegate: MockIMainSettingsInteractorDelegate!

    private var mockLocalStorage: MockILocalStorage!
    private var mockBackupManager: MockIBackupManager!
    private var mockLanguageManager: MockILanguageManager!
    private var mockSystemInfoManager: MockISystemInfoManager!
    private var mockCurrencyManager: MockICurrencyManager!
    private var mockAppConfigProvider: MockIAppConfigProvider!

    private var interactor: MainSettingsInteractor!

    private let nonBackedUpCountSubject = PublishSubject<Int>()
    private let baseCurrencyUpdatedSignal = Signal()

    override func setUp() {
        super.setUp()

        mockDelegate = MockIMainSettingsInteractorDelegate()

        mockLocalStorage = MockILocalStorage()
        mockBackupManager = MockIBackupManager()
        mockLanguageManager = MockILanguageManager()
        mockSystemInfoManager = MockISystemInfoManager()
        mockCurrencyManager = MockICurrencyManager()
        mockAppConfigProvider = MockIAppConfigProvider()

        stub(mockBackupManager) { mock in
            when(mock.nonBackedUpCountObservable.get).thenReturn(nonBackedUpCountSubject.asObservable())
        }
        stub(mockCurrencyManager) { mock in
            when(mock.baseCurrencyUpdatedSignal.get).thenReturn(baseCurrencyUpdatedSignal)
        }

        interactor = MainSettingsInteractor(localStorage: mockLocalStorage, backupManager: mockBackupManager, languageManager: mockLanguageManager, systemInfoManager: mockSystemInfoManager, currencyManager: mockCurrencyManager, appConfigProvider: mockAppConfigProvider, async: false)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil

        mockLocalStorage = nil
        mockBackupManager = nil
        mockLanguageManager = nil
        mockSystemInfoManager = nil
        mockCurrencyManager = nil
        mockAppConfigProvider = nil

        interactor = nil

        super.tearDown()
    }

    func testNonBackedUpCount() {
        let count = 2

        stub(mockBackupManager) { mock in
            when(mock.nonBackedUpCount.get).thenReturn(count)
        }

        XCTAssertEqual(interactor.nonBackedUpCount, count)
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

    func testNonBackedUpCountObservable() {
        let count = 3

        stub(mockDelegate) { mock in
            when(mock.didUpdateNonBackedUp(count: any())).thenDoNothing()
        }

        nonBackedUpCountSubject.onNext(count)

        verify(mockDelegate).didUpdateNonBackedUp(count: count)
    }

    func testBaseCurrencyUpdatedSignal() {
        stub(mockDelegate) { mock in
            when(mock.didUpdateBaseCurrency()).thenDoNothing()
        }

        baseCurrencyUpdatedSignal.notify()

        verify(mockDelegate).didUpdateBaseCurrency()
    }

}
