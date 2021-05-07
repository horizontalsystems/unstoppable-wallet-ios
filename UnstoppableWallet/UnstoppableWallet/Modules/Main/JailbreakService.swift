import RxSwift

class JailbreakService {
    private let localStorage: ILocalStorage
    private let jailbreakTestManager: JailbreakTestManager

    init(localStorage: ILocalStorage, jailbreakTestManager: JailbreakTestManager) {
        self.localStorage = localStorage
        self.jailbreakTestManager = jailbreakTestManager
    }

    var needToShowAlert: Bool {
        !localStorage.jailbreakShownOnce && jailbreakTestManager.isJailbroken
    }

    func setAlertShown() {
        localStorage.jailbreakShownOnce = true
    }

}
