import XCTest
import RxSwift
import Cuckoo
@testable import Bank

class MainSettingsInteractorTests: XCTestCase {
    private var mockDelegate: MockIMainSettingsInteractorDelegate!
    private var mockLocalStorage: MockILocalStorage!
    private var mockWordsManager: MockWordsManager!
    private var mockLanguageManager: MockILanguageManager!

    private var interactor: MainSettingsInteractor!

    let currentLanguageDisplayName = "Chitaurian"
    let backedUpSubject = PublishSubject<Bool>()

    override func setUp() {
        super.setUp()

        let mockApp = MockApp()

        mockDelegate = MockIMainSettingsInteractorDelegate()
        mockLocalStorage = mockApp.mockLocalStorage
        mockWordsManager = mockApp.mockWordsManager
        mockLanguageManager = mockApp.mockLanguageManager

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

        interactor = MainSettingsInteractor(localStorage: mockLocalStorage, wordsManager: mockWordsManager, languageManager: mockLanguageManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockLocalStorage = nil
        mockLanguageManager = nil

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

}
