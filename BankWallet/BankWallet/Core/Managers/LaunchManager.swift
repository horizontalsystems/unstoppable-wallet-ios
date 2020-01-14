import Foundation

class LaunchManager {
    private let localStorage: ILocalStorage
    private let secureStorage: ISecureStorage

    init(localStorage: ILocalStorage, secureStorage: ISecureStorage) {
        self.localStorage = localStorage
        self.secureStorage = secureStorage
    }

    private func handleDidLaunchOnce() {
        if !localStorage.didLaunchOnce {
            try? secureStorage.clear()
            localStorage.didLaunchOnce = true
        }
    }

}

extension LaunchManager: ILaunchManager {

    func handleFirstLaunch() {
        self.handleDidLaunchOnce()
    }

}

protocol ILaunchManager {
    func handleFirstLaunch()
}
