import XCTest
import Cuckoo
@testable import Bank

class UnlockPinInteractorTests: XCTestCase {
    private var mockDelegate: MockIUnlockPinInteractorDelegate!
    private var mockPinManager: MockPinManager!
    private var mockBiometricManager: MockBiometricManager!
    private var mockAppHelper: MockAppHelper!
    private var interactor: UnlockPinInteractor!

    override func setUp() {
        super.setUp()

        mockDelegate = MockIUnlockPinInteractorDelegate()
        mockPinManager = MockPinManager()
        mockBiometricManager = MockBiometricManager()
        mockAppHelper = MockAppHelper()
        interactor = UnlockPinInteractor(pinManager: mockPinManager, biometricManager: mockBiometricManager, appHelper: mockAppHelper)
        interactor.delegate = mockDelegate

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
    }

    override func tearDown() {
        mockDelegate = nil
        mockPinManager = nil
        mockBiometricManager = nil
        mockAppHelper = nil
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
        stub(mockAppHelper) { mock in
            when(mock.isBiometricUnlockOn.get).thenReturn(true)
        }

        interactor.biometricUnlock()

        verify(mockBiometricManager).validate(reason: "biometric_usage_reason")
    }

    func testBiometricUnlockWhenDisabled() {
        stub(mockAppHelper) { mock in
            when(mock.isBiometricUnlockOn.get).thenReturn(false)
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
