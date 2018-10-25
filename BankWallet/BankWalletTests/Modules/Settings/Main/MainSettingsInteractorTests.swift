import XCTest
import RxSwift
import Cuckoo
@testable import BankWallet

class MainSettingsInteractorTests: XCTestCase {
    private var mockDelegate: MockIMainSettingsInteractorDelegate!
    private var mockLocalStorage: MockILocalStorage!
    private var mockWordsManager: MockIWordsManager!
    private var mockLanguageManager: MockILanguageManager!
    private var mockSystemInfoManager: MockISystemInfoManager!

    private var interactor: MainSettingsInteractor!

    let currentLanguageDisplayName = "Chitaurian"
    let backedUpSubject = PublishSubject<Bool>()
    let appVersion = "1"

    override func setUp() {
        super.setUp()

        mockDelegate = MockIMainSettingsInteractorDelegate()
        mockLocalStorage = MockILocalStorage()
        mockWordsManager = MockIWordsManager()
        mockLanguageManager = MockILanguageManager()
        mockSystemInfoManager = MockISystemInfoManager()

        stub(mockDelegate) { mock in
            when(mock.didUpdateLightMode()).thenDoNothing()
            when(mock.didBackup()).thenDoNothing()
        }
        stub(mockLocalStorage) { mock in
            when(mock.lightMode.get).thenReturn(true)
            when(mock.lightMode.set(any())).thenDoNothing()
        }
        stub(mockWordsManager) { mock in
            when(mock.isBackedUp.get).thenReturn(true)
            when(mock.backedUpSubject.get).thenReturn(backedUpSubject)
        }
        stub(mockLanguageManager) { mock in
            when(mock.displayNameForCurrentLanguage.get).thenReturn(currentLanguageDisplayName)
        }
        stub(mockSystemInfoManager) { mock in
            when(mock.appVersion.get).thenReturn(appVersion)
        }

        interactor = MainSettingsInteractor(localStorage: mockLocalStorage, wordsManager: mockWordsManager, languageManager: mockLanguageManager, systemInfoManager: mockSystemInfoManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockLocalStorage = nil
        mockLanguageManager = nil
        mockSystemInfoManager = nil

        interactor = nil

        super.tearDown()
    }

    func testIsBackedUp() {
        XCTAssertTrue(interactor.isBackedUp)
    }

    func testIsNotBackedUp() {
        stub(mockWordsManager) { mock in
            when(mock.isBackedUp.get).thenReturn(false)
        }

        XCTAssertFalse(interactor.isBackedUp)
    }

    func testBackedUpSubjectTrue() {
        backedUpSubject.onNext(true)
        verify(mockDelegate).didBackup()
    }

    func testBackedUpSubjectFalse() {
        backedUpSubject.onNext(false)
        verify(mockDelegate, never()).didBackup()
    }

    func testCurrentLanguage() {
        XCTAssertEqual(interactor.currentLanguage, currentLanguageDisplayName)
    }

    func testLightModeOn() {
        XCTAssertTrue(interactor.lightMode)
    }

    func testLightModeOff() {
        stub(mockLocalStorage) { mock in
            when(mock.lightMode.get).thenReturn(false)
        }

        XCTAssertFalse(interactor.lightMode)
    }

    func testSetLightModeOn() {
        interactor.set(lightMode: true)
        verify(mockLocalStorage).lightMode.set(true)
        verify(mockDelegate).didUpdateLightMode()
    }

    func testSetLightModeOff() {
        interactor.set(lightMode: false)
        verify(mockLocalStorage).lightMode.set(false)
        verify(mockDelegate).didUpdateLightMode()
    }

    func testAppVersion() {
        XCTAssertEqual(interactor.appVersion, appVersion)
    }

}
