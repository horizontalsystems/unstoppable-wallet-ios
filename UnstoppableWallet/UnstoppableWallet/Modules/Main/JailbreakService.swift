class JailbreakService {
    private let localStorage = Core.shared.localStorage
    private let jailbreakTestManager = JailbreakTestManager()

    var needToShowAlert: Bool {
        !localStorage.jailbreakShownOnce && jailbreakTestManager.isJailbroken
    }

    func setAlertShown() {
        localStorage.jailbreakShownOnce = true
    }
}
