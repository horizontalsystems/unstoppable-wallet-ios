//import XCTest
//import Cuckoo
//@testable import Bank_Dev_T
//
//class SecuritySettingsPresenterTests: XCTestCase {
//    private var mockRouter: MockISecuritySettingsRouter!
//    private var mockInteractor: MockISecuritySettingsInteractor!
//    private var mockView: MockISecuritySettingsView!
//
//    private var state: SecuritySettingsState!
//
//    private var presenter: SecuritySettingsPresenter!
//
//    override func setUp() {
//        super.setUp()
//
//        mockRouter = MockISecuritySettingsRouter()
//        mockInteractor = MockISecuritySettingsInteractor()
//        mockView = MockISecuritySettingsView()
//
//        state = SecuritySettingsState()
//
//        stub(mockView) { mock in
//            when(mock.set(title: any())).thenDoNothing()
//            when(mock.set(biometricUnlockOn: any())).thenDoNothing()
//            when(mock.set(biometryType: any())).thenDoNothing()
//            when(mock.set(backedUp: any())).thenDoNothing()
//            when(mock.set(isPinSet: any())).thenDoNothing()
//        }
//        stub(mockRouter) { mock in
//            when(mock.showEditPin()).thenDoNothing()
//            when(mock.showUnlock()).thenDoNothing()
//        }
//        stub(mockInteractor) { mock in
//            when(mock.nonBackedUpCount.get).thenReturn(0)
//            when(mock.isBiometricUnlockOn.get).thenReturn(true)
//            when(mock.isPinSet.get).thenReturn(false)
//            when(mock.getBiometryType()).thenDoNothing()
//            when(mock.set(biometricUnlockOn: any())).thenDoNothing()
//        }
//
//        presenter = SecuritySettingsPresenter(router: mockRouter, interactor: mockInteractor, state: state)
//        presenter.view = mockView
//    }
//
//    override func tearDown() {
//        mockRouter = nil
//        mockInteractor = nil
//        mockView = nil
//        state = nil
//
//        presenter = nil
//
//        super.tearDown()
//    }
//
//    func testShowTitle() {
//        presenter.viewDidLoad()
//
//        verify(mockView).set(title: "settings_security.title")
//    }
//
//    func testSetBiometricUnlockOnOnLoad() {
//        presenter.viewDidLoad()
//
//        verify(mockView).set(biometricUnlockOn: true)
//    }
//
//    func testSetBiometricUnlockOffOnLoad() {
//        stub(mockInteractor) { mock in
//            when(mock.isBiometricUnlockOn.get).thenReturn(false)
//        }
//
//        presenter.viewDidLoad()
//
//        verify(mockView).set(biometricUnlockOn: false)
//    }
//
//    func testAskForBiometryTypeOnLoad() {
//        presenter.viewDidLoad()
//        verify(mockInteractor).getBiometryType()
//    }
//
//    func testSetBiometryType() {
//        presenter.didGetBiometry(type: .faceId)
//        verify(mockView).set(biometryType: equal(to: BiometryType.faceId))
//    }
//
//    func testNotBackedUpCountOnLoad_Zero() {
//        stub(mockInteractor) { mock in
//            when(mock.nonBackedUpCount.get).thenReturn(0)
//        }
//
//        presenter.viewDidLoad()
//
//        verify(mockView).set(backedUp: true)
//    }
//
//    func testNotBackedUpCountOnLoad_NonZero() {
//        let count = 2
//
//        stub(mockInteractor) { mock in
//            when(mock.nonBackedUpCount.get).thenReturn(count)
//        }
//
//        presenter.viewDidLoad()
//
//        verify(mockView).set(backedUp: false)
//    }
//
//    func testDidSwitchBiometricUnlockOn() {
//        presenter.didSwitch(biometricUnlockOn: true)
//
//        verify(mockRouter).showUnlock()
//        XCTAssertEqual(state.unlockType!, SecuritySettingsUnlockType.biometry(isOn: true))
//    }
//
//    func testDidSwitchBiometricUnlockOff() {
//        presenter.didSwitch(biometricUnlockOn: false)
//
//        verify(mockRouter).showUnlock()
//        XCTAssertEqual(state.unlockType!, SecuritySettingsUnlockType.biometry(isOn: false))
//    }
//
//    func testDidTapEditPin() {
//        presenter.didTapEditPin()
//
//        verify(mockRouter).showEditPin()
//    }
//
//    func testDidUpdateNonBackedUp_Zero() {
//        presenter.didUpdateNonBackedUp(count: 0)
//
//        verify(mockView).set(backedUp: true)
//    }
//
//    func testDidUpdateNonBackedUp_NonZero() {
//        let count = 3
//
//        presenter.didUpdateNonBackedUp(count: count)
//
//        verify(mockView).set(backedUp: false)
//    }
//
//    func testOnUnlockBiometryTypeOn() {
//        state.unlockType = .biometry(isOn: true)
//
//        presenter.onUnlock()
//
//        verify(mockInteractor).set(biometricUnlockOn: true)
//        XCTAssertEqual(state.unlockType, nil)
//    }
//
//    func testOnUnlockBiometryTypeOff() {
//        state.unlockType = .biometry(isOn: false)
//
//        presenter.onUnlock()
//
//        verify(mockInteractor).set(biometricUnlockOn: false)
//        XCTAssertEqual(state.unlockType, nil)
//    }
//
//    func testOnCancelUnlock() {
//        stub(mockInteractor) { mock in
//            when(mock.isBiometricUnlockOn.get).thenReturn(false)
//        }
//
//        presenter.onCancelUnlock()
//
//        verify(mockView).set(biometricUnlockOn: false)
//        XCTAssertEqual(state.unlockType, nil)
//    }
//
//}
