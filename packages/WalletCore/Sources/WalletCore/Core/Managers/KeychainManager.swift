class KeychainManager {
    private let keyDidLaunchOnce = "did_launch_once_key"

    private let storage: KeychainStorage
    private let userDefaultsStorage: UserDefaultsStorage

    init(storage: KeychainStorage, userDefaultsStorage: UserDefaultsStorage) {
        self.storage = storage
        self.userDefaultsStorage = userDefaultsStorage
    }
}

extension KeychainManager {
    func handleLaunch() {
        let didLaunchOnce = userDefaultsStorage.value(for: keyDidLaunchOnce) ?? false

        if !didLaunchOnce {
            try? storage.clear()
            userDefaultsStorage.set(value: true, for: keyDidLaunchOnce)
        }
    }
}
