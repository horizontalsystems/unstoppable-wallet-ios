import XCTest
import RxSwift
import Cuckoo
@testable import Bank

class SecuritySettingsInteractorTests: XCTestCase {
    private var mockDelegate: MockISecuritySettingsInteractorDelegate!
    private var mockWordsManager: MockIWordsManager!
    private var mockLocalStorage: MockILocalStorage!

    private var interactor: SecuritySettingsInteractor!

    let backedUpSubject = PublishSubject<Bool>()

    override func setUp() {
        super.setUp()

        mockDelegate = MockISecuritySettingsInteractorDelegate()
        mockWordsManager = MockIWordsManager()
        mockLocalStorage = MockILocalStorage()

        stub(mockDelegate) { mock in
            when(mock.didBackup()).thenDoNothing()
        }
        stub(mockWordsManager) { mock in
            when(mock.isBackedUp.get).thenReturn(true)
            when(mock.backedUpSubject.get).thenReturn(backedUpSubject)
        }
        stub(mockLocalStorage) { mock in
            when(mock.isBiometricOn.get).thenReturn(true)
            when(mock.isBiometricOn.set(any())).thenDoNothing()
        }

        interactor = SecuritySettingsInteractor(localStorage: mockLocalStorage, wordsManager: mockWordsManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockWordsManager = nil
        mockLocalStorage = nil

        interactor = nil

        super.tearDown()
    }

    func testIsBiometricUnlockOn() {
        XCTAssertTrue(interactor.isBiometricUnlockOn)
    }

    func testIsBiometricUnlockOff() {
        stub(mockLocalStorage) { mock in
            when(mock.isBiometricOn.get).thenReturn(false)
        }

        XCTAssertFalse(interactor.isBiometricUnlockOn)
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

    func testSetBiometricUnlockOn() {
        interactor.set(biometricUnlockOn: true)
        verify(mockLocalStorage).isBiometricOn.set(true)
    }

    func testSetBiometricUnlockOff() {
        interactor.set(biometricUnlockOn: false)
        verify(mockLocalStorage).isBiometricOn.set(false)
    }

}
