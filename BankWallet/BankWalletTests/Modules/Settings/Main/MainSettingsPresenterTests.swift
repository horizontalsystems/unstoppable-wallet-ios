import XCTest
import Cuckoo
@testable import Bank_Dev_T

class MainSettingsPresenterTests: XCTestCase {
    private var mockRouter: MockIMainSettingsRouter!
    private var mockInteractor: MockIMainSettingsInteractor!
    private var mockView: MockIMainSettingsView!

    private var presenter: MainSettingsPresenter!

    private let defaultLanguage = "English"
    private let baseCurrency = "USD"
    private let appVersion = "1"

    override func setUp() {
        super.setUp()

        mockRouter = MockIMainSettingsRouter()
        mockInteractor = MockIMainSettingsInteractor()
        mockView = MockIMainSettingsView()

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.set(backedUp: any())).thenDoNothing()
            when(mock.set(language: any())).thenDoNothing()
            when(mock.set(baseCurrency: any())).thenDoNothing()
            when(mock.set(lightMode: any())).thenDoNothing()
            when(mock.set(appVersion: any())).thenDoNothing()
            when(mock.setTabItemBadge(count: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.showSecuritySettings()).thenDoNothing()
            when(mock.showBaseCurrencySettings()).thenDoNothing()
            when(mock.showLanguageSettings()).thenDoNothing()
            when(mock.showAbout()).thenDoNothing()
            when(mock.openAppLink()).thenDoNothing()
            when(mock.reloadAppInterface()).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.isBackedUp.get).thenReturn(true)
            when(mock.currentLanguage.get).thenReturn(defaultLanguage)
            when(mock.baseCurrency.get).thenReturn(baseCurrency)
            when(mock.lightMode.get).thenReturn(true)
            when(mock.appVersion.get).thenReturn(appVersion)
            when(mock.set(lightMode: any())).thenDoNothing()
        }

        presenter = MainSettingsPresenter(router: mockRouter, interactor: mockInteractor)
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

        verify(mockView).set(title: "settings.title")
    }

    func testBackedUpOnLoad() {
        presenter.viewDidLoad()

        verify(mockView).set(backedUp: true)
        verify(mockView).setTabItemBadge(count: 0)
    }

    func testNotBackedUpOnLoad() {
        stub(mockInteractor) { mock in
            when(mock.isBackedUp.get).thenReturn(false)
        }

        presenter.viewDidLoad()

        verify(mockView).set(backedUp: false)
        verify(mockView).setTabItemBadge(count: 1)
    }

    func testShowCurrentLanguageOnLoad() {
        presenter.viewDidLoad()

        verify(mockView).set(language: defaultLanguage)
    }

    func testShowCurrencyOnLoad() {
        presenter.viewDidLoad()

        verify(mockView).set(baseCurrency: baseCurrency)
    }

    func testShowLightModeIsOnOnLoad() {
        presenter.viewDidLoad()

        verify(mockView).set(lightMode: true)
    }

    func testShowLightModeIsOffOnLoad() {
        stub(mockInteractor) { mock in
            when(mock.lightMode.get).thenReturn(false)
        }

        presenter.viewDidLoad()

        verify(mockView).set(lightMode: false)
    }

    func testShowAppVersionOnLoad() {
        presenter.viewDidLoad()
        verify(mockView).set(appVersion: appVersion)
    }

    func testDidBackup() {
        presenter.didBackup()

        verify(mockView).set(backedUp: true)
        verify(mockView).setTabItemBadge(count: 0)
    }

    func testReloadAppInterfaceOnLightModeUpdate() {
        presenter.didUpdateLightMode()
        verify(mockRouter).reloadAppInterface()
    }

    func testDidTapSecurity() {
        presenter.didTapSecurity()
        verify(mockRouter).showSecuritySettings()
    }

    func testDidTapBaseCurrency() {
        presenter.didTapBaseCurrency()
        verify(mockRouter).showBaseCurrencySettings()
    }

    func testDidTapLanguage() {
        presenter.didTapLanguage()
        verify(mockRouter).showLanguageSettings()
    }

    func testDidTapAbout() {
        presenter.didTapAbout()
        verify(mockRouter).showAbout()
    }

    func testDidTapAppLink() {
        presenter.didTapAppLink()
        verify(mockRouter).openAppLink()
    }

    func testDidSwitchLightModeOn() {
        presenter.didSwitch(lightMode: true)
        verify(mockInteractor).set(lightMode: true)
    }

    func testDidSwitchLightModeOff() {
        presenter.didSwitch(lightMode: false)
        verify(mockInteractor).set(lightMode: false)
    }

}
