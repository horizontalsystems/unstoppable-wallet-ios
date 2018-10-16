import XCTest
import Cuckoo
@testable import Bank

class SecuritySettingsPresenterTests: XCTestCase {
    private var mockRouter: MockISecuritySettingsRouter!
    private var mockInteractor: MockISecuritySettingsInteractor!
    private var mockView: MockISecuritySettingsView!

    private var presenter: SecuritySettingsPresenter!

    override func setUp() {
        super.setUp()

        mockRouter = MockISecuritySettingsRouter()
        mockInteractor = MockISecuritySettingsInteractor()
        mockView = MockISecuritySettingsView()

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.set(biometricUnlockOn: any())).thenDoNothing()
            when(mock.set(backedUp: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.showEditPin()).thenDoNothing()
            when(mock.showSecretKey()).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.isBiometricUnlockOn.get).thenReturn(true)
            when(mock.isBackedUp.get).thenReturn(true)
            when(mock.set(biometricUnlockOn: any())).thenDoNothing()
        }

        presenter = SecuritySettingsPresenter(router: mockRouter, interactor: mockInteractor)
        presenter.view = mockView
    }

    override func tearDown() {
        mockRouter = nil
        mockInteractor = nil
        mockView = nil

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

        verify(mockInteractor).set(biometricUnlockOn: true)
    }

    func testDidSwitchBiometricUnlockOff() {
        presenter.didSwitch(biometricUnlockOn: false)

        verify(mockInteractor).set(biometricUnlockOn: false)
    }

    func testDidTapEditPin() {
        presenter.didTapEditPin()

        verify(mockRouter).showEditPin()
    }

    func testDidTapSecretKey() {
        presenter.didTapSecretKey()

        verify(mockRouter).showSecretKey()
    }

    func testDidBackup() {
        presenter.didBackup()

        verify(mockView).set(backedUp: true)
    }

}
