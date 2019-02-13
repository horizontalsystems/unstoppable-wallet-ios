import XCTest
import Cuckoo
@testable import Bank_Dev_T

class SecuritySettingsInteractorTests: XCTestCase {
    private var mockDelegate: MockISecuritySettingsInteractorDelegate!

    private var mockLocalStorage: MockILocalStorage!
    private var mockAuthManager: MockIAuthManager!
    private var mockWordsManager: MockIWordsManager!
    private var mockSystemInfoManager: MockISystemInfoManager!

    private var interactor: SecuritySettingsInteractor!

    private let backedUpSignal = Signal()

    override func setUp() {
        super.setUp()

        mockDelegate = MockISecuritySettingsInteractorDelegate()

        mockLocalStorage = MockILocalStorage()
        mockAuthManager = MockIAuthManager()
        mockWordsManager = MockIWordsManager()
        mockSystemInfoManager = MockISystemInfoManager()

        stub(mockWordsManager) { mock in
            when(mock.backedUpSignal.get).thenReturn(backedUpSignal)
        }

        interactor = SecuritySettingsInteractor(localStorage: mockLocalStorage, authManager: mockAuthManager, wordsManager: mockWordsManager, systemInfoManager: mockSystemInfoManager)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil

        mockLocalStorage = nil
        mockAuthManager = nil
        mockWordsManager = nil
        mockSystemInfoManager = nil

        interactor = nil

        super.tearDown()
    }

    func testIsBiometricUnlockOn() {
        stub(mockLocalStorage) { mock in
            when(mock.isBiometricOn.get).thenReturn(true)
        }

        XCTAssertTrue(interactor.isBiometricUnlockOn)
    }

    func testIsBiometricUnlockOn_false() {
        stub(mockLocalStorage) { mock in
            when(mock.isBiometricOn.get).thenReturn(false)
        }

        XCTAssertFalse(interactor.isBiometricUnlockOn)
    }

    func testBiometryType() {
        let biometryType: BiometryType = .faceId

        stub(mockSystemInfoManager) { mock in
            when(mock.biometryType.get).thenReturn(biometryType)
        }

        XCTAssertEqual(interactor.biometryType, biometryType)
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

    func testSetBiometricUnlockOn() {
        stub(mockLocalStorage) { mock in
            when(mock.isBiometricOn.set(any())).thenDoNothing()
        }

        interactor.set(biometricUnlockOn: true)

        verify(mockLocalStorage).isBiometricOn.set(true)
    }

    func testSetBiometricUnlockOn_false() {
        stub(mockLocalStorage) { mock in
            when(mock.isBiometricOn.set(any())).thenDoNothing()
        }

        interactor.set(biometricUnlockOn: false)

        verify(mockLocalStorage).isBiometricOn.set(false)
    }

    func testUnlink() {
        stub(mockAuthManager) { mock in
            when(mock.logout()).thenDoNothing()
        }
        stub(mockDelegate) { mock in
            when(mock.didUnlink()).thenDoNothing()
        }

        interactor.unlink()

        verify(mockAuthManager).logout()
        verify(mockDelegate).didUnlink()
    }

    func testUnlink_error() {
        struct UnlinkError: Error {}

        stub(mockAuthManager) { mock in
            when(mock.logout()).thenThrow(UnlinkError())
        }

        interactor.unlink()

        verify(mockAuthManager).logout()
        verify(mockDelegate, never()).didUnlink()
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

}
