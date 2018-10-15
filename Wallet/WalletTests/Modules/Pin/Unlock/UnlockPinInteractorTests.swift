import XCTest
import Cuckoo
@testable import Bank

class UnlockPinInteractorTests: XCTestCase {
    private var mockDelegate: MockIUnlockPinInteractorDelegate!
    private var mockPinManager: MockPinManager!
    private var mockBiometricManager: MockBiometricManager!
    private var mockLocalStorage: MockILocalStorage!
    private var interactor: UnlockPinInteractor!

    override func setUp() {
        super.setUp()

        let mockApp = MockApp()

        mockDelegate = MockIUnlockPinInteractorDelegate()
        mockPinManager = mockApp.mockPinManager
        mockBiometricManager = MockBiometricManager()
        mockLocalStorage = mockApp.mockLocalStorage

        stub(mockDelegate) { mock in
            when(mock.didBiometricUnlock()).thenDoNothing()
            when(mock.didFailBiometricUnlock()).thenDoNothing()
        }
        stub(mockPinManager) { mock in
            when(mock.store(pin: any())).thenDoNothing()
        }
        stub(mockBiometricManager) { mock in
            when(mock.validate(reason: any())).thenDoNothing()
        }

        interactor = UnlockPinInteractor(pinManager: mockPinManager, biometricManager: mockBiometricManager, localStorage: mockLocalStorage)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockPinManager = nil
        mockBiometricManager = nil
        mockLocalStorage = nil
        interactor = nil

        super.tearDown()
    }

    func testUnlockSuccess() {
        let pin = "0000"
        stub(mockPinManager) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(true)
        }

        let isValid = interactor.unlock(with: pin)

        XCTAssertTrue(isValid)
    }

    func testUnlockFailure() {
        let pin = "0000"
        stub(mockPinManager) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(false)
        }

        let isValid = interactor.unlock(with: pin)

        XCTAssertFalse(isValid)
    }

    func testBiometricUnlockWhenEnabled() {
        stub(mockLocalStorage) { mock in
            when(mock.isBiometricOn.get).thenReturn(true)
        }

        interactor.biometricUnlock()

        verify(mockBiometricManager).validate(reason: "biometric_usage_reason")
    }

    func testBiometricUnlockWhenDisabled() {
        stub(mockLocalStorage) { mock in
            when(mock.isBiometricOn.get).thenReturn(false)
        }

        interactor.biometricUnlock()

        verify(mockDelegate).didFailBiometricUnlock()
        verify(mockBiometricManager, never()).validate(reason: any())
    }

    func testDidBiometricValidate() {
        interactor.didValidate()
        verify(mockDelegate).didBiometricUnlock()
    }

    func testDidFailBiometricValidate() {
        interactor.didFailToValidate()
        verify(mockDelegate).didFailBiometricUnlock()
    }

}
