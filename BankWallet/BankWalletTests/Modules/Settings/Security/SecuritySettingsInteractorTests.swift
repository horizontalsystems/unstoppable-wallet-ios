import XCTest
import Cuckoo
import RxSwift
@testable import Bank_Dev_T

class SecuritySettingsInteractorTests: XCTestCase {
    private var mockDelegate: MockISecuritySettingsInteractorDelegate!

    private var mockLocalStorage: MockILocalStorage!
    private var mockAccountManager: MockIAccountManager!
    private var mockSystemInfoManager: MockISystemInfoManager!

    private var interactor: SecuritySettingsInteractor!

    private let nonBackedUpCountSubject = PublishSubject<Int>()

    override func setUp() {
        super.setUp()

        mockDelegate = MockISecuritySettingsInteractorDelegate()

        mockLocalStorage = MockILocalStorage()
        mockAccountManager = MockIAccountManager()
        mockSystemInfoManager = MockISystemInfoManager()

        stub(mockAccountManager) { mock in
            when(mock.nonBackedUpCountObservable.get).thenReturn(nonBackedUpCountSubject.asObservable())
        }

        interactor = SecuritySettingsInteractor(localStorage: mockLocalStorage, accountManager: mockAccountManager, systemInfoManager: mockSystemInfoManager, async: false)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil

        mockLocalStorage = nil
        mockAccountManager = nil
        mockSystemInfoManager = nil

        interactor = nil

        super.tearDown()
    }

    func testNonBackedUpCount() {
        let count = 2

        stub(mockAccountManager) { mock in
            when(mock.nonBackedUpCount.get).thenReturn(count)
        }

        XCTAssertEqual(interactor.nonBackedUpCount, count)
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
            when(mock.biometryType.get).thenReturn(Single.just(biometryType))
        }
        stub(mockDelegate) { mock in
            when(mock.didGetBiometry(type: any())).thenDoNothing()
        }

        interactor.getBiometryType()

        verify(mockDelegate).didGetBiometry(type: equal(to: biometryType))
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

    func testNonBackedUpCountObservable() {
        let count = 3

        stub(mockDelegate) { mock in
            when(mock.didUpdateNonBackedUp(count: any())).thenDoNothing()
        }

        nonBackedUpCountSubject.onNext(count)

        verify(mockDelegate).didUpdateNonBackedUp(count: count)
    }

    func testOnUnlock() {
        stub(mockDelegate) { mock in
            when(mock.onUnlock()).thenDoNothing()
        }

        interactor.onUnlock()

        verify(mockDelegate).onUnlock()
    }

    func testOnCancelUnlock() {
        stub(mockDelegate) { mock in
            when(mock.onCancelUnlock()).thenDoNothing()
        }

        interactor.onCancelUnlock()

        verify(mockDelegate).onCancelUnlock()
    }

}
