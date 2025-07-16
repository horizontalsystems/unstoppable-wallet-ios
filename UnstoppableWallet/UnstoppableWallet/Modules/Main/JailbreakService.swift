class JailbreakService {
    private let localStorage: LocalStorage
    private let jailbreakTestManager = JailbreakTestManager()

    init(localStorage: LocalStorage) {
        self.localStorage = localStorage
    }

    var needToShowAlert: Bool {
        !localStorage.jailbreakShownOnce && jailbreakTestManager.isJailbroken
    }

    func setAlertShown() {
        localStorage.jailbreakShownOnce = true
    }
}
