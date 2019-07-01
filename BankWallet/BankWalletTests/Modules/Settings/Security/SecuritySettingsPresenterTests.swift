import XCTest
import Cuckoo
@testable import Bank_Dev_T

class SecuritySettingsPresenterTests: XCTestCase {
    private var mockRouter: MockISecuritySettingsRouter!
    private var mockInteractor: MockISecuritySettingsInteractor!
    private var mockView: MockISecuritySettingsView!

    private var state: SecuritySettingsState!

    private var presenter: SecuritySettingsPresenter!

    override func setUp() {
        super.setUp()

        mockRouter = MockISecuritySettingsRouter()
        mockInteractor = MockISecuritySettingsInteractor()
        mockView = MockISecuritySettingsView()

        state = SecuritySettingsState()

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.set(biometricUnlockOn: any())).thenDoNothing()
            when(mock.set(biometryType: any())).thenDoNothing()
            when(mock.set(backedUp: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.showEditPin()).thenDoNothing()
            when(mock.showUnlock()).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.isBiometricUnlockOn.get).thenReturn(true)
            when(mock.getBiometryType()).thenDoNothing()
            when(mock.isBackedUp.get).thenReturn(true)
            when(mock.set(biometricUnlockOn: any())).thenDoNothing()
        }

        presenter = SecuritySettingsPresenter(router: mockRouter, interactor: mockInteractor, state: state)
        presenter.view = mockView
    }

    override func tearDown() {
        mockRouter = nil
        mockInteractor = nil
        mockView = nil
        state = nil

        presenter = nil

        super.tearDown()
    }

    func testShowTitle() {
        presenter.viewDidLoad()

        verify(mockView).set(title: "settings_security.title")
    }

    func testSetBiometricUnlockOnOnLoad() {
        presenter.viewDidLoad()

        verify(mockView).set(biometricUnlockOn: true)
    }

    func testSetBiometricUnlockOffOnLoad() {
        stub(mockInteractor) { mock in
            when(mock.isBiometricUnlockOn.get).thenReturn(false)
        }

        presenter.viewDidLoad()

        verify(mockView).set(biometricUnlockOn: false)
    }

    func testAskForBiometryTypeOnLoad() {
        presenter.viewDidLoad()
        verify(mockInteractor).getBiometryType()
    }

    func testSetBiometryType() {
        presenter.didGetBiometry(type: .faceId)
        verify(mockView).set(biometryType: equal(to: BiometryType.faceId))
    }

    func testBackedUpOnLoad() {
        presenter.viewDidLoad()

        verify(mockView).set(backedUp: true)
    }

    func testNotBackedUpOnLoad() {
        stub(mockInteractor) { mock in
            when(mock.isBackedUp.get).thenReturn(false)
        }

        presenter.viewDidLoad()

        verify(mockView).set(backedUp: false)
    }

    func testDidSwitchBiometricUnlockOn() {
        presenter.didSwitch(biometricUnlockOn: true)

        verify(mockRouter).showUnlock()
        XCTAssertEqual(state.unlockType!, SecuritySettingsUnlockType.biometry(isOn: true))
    }

    func testDidSwitchBiometricUnlockOff() {
        presenter.didSwitch(biometricUnlockOn: false)

        verify(mockRouter).showUnlock()
        XCTAssertEqual(state.unlockType!, SecuritySettingsUnlockType.biometry(isOn: false))
    }

    func testDidTapEditPin() {
        presenter.didTapEditPin()

        verify(mockRouter).showEditPin()
    }

    func testDidBackup() {
        presenter.didBackup()
        verify(mockView).set(backedUp: true)
    }

    func testOnUnlockBiometryTypeOn() {
        state.unlockType = .biometry(isOn: true)

        presenter.onUnlock()

        verify(mockInteractor).set(biometricUnlockOn: true)
        XCTAssertEqual(state.unlockType, nil)
    }

    func testOnUnlockBiometryTypeOff() {
        state.unlockType = .biometry(isOn: false)

        presenter.onUnlock()

        verify(mockInteractor).set(biometricUnlockOn: false)
        XCTAssertEqual(state.unlockType, nil)
    }

    func testOnCancelUnlock() {
        stub(mockInteractor) { mock in
            when(mock.isBiometricUnlockOn.get).thenReturn(false)
        }

        presenter.onCancelUnlock()

        verify(mockView).set(biometricUnlockOn: false)
        XCTAssertEqual(state.unlockType, nil)
    }

}
