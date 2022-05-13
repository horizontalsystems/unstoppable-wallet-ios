import RxSwift

class JailbreakService {
    private let localStorage: LocalStorage
    private let jailbreakTestManager: JailbreakTestManager

    init(localStorage: LocalStorage, jailbreakTestManager: JailbreakTestManager) {
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
