import Combine
import HsExtensions
import StorageKit

class PasscodeManager {
    private let separator = "|"
    private let passcodeKey = "pin_keychain_key"

    private let biometryManager: BiometryManager
    private let secureStorage: ISecureStorage

    private var passcodes = [String]()

    @PostPublished private(set) var currentPasscodeLevel: Int
    @PostPublished private(set) var isPasscodeSet = false
    @PostPublished private(set) var isDuressPasscodeSet = false

    init(biometryManager: BiometryManager, secureStorage: ISecureStorage) {
        self.biometryManager = biometryManager
        self.secureStorage = secureStorage

        if let rawPasscodes: String = secureStorage.value(for: passcodeKey), !rawPasscodes.isEmpty {
            passcodes = rawPasscodes.components(separatedBy: separator)
        } else {
            passcodes = [""]
        }

        currentPasscodeLevel = passcodes.count - 1

        syncState()
    }

    private func syncState() {
        isPasscodeSet = passcodes.last.map { !$0.isEmpty } ?? false
        isDuressPasscodeSet = passcodes.count > currentPasscodeLevel + 1

        if !isPasscodeSet, biometryManager.biometryEnabled {
            biometryManager.biometryEnabled = false
        }
    }

    private func save(passcodes: [String]) throws {
        try secureStorage.set(value: passcodes.joined(separator: separator), for: passcodeKey)
    }
}

extension PasscodeManager {
    func isValid(passcode: String) -> Bool {
        passcodes[currentPasscodeLevel] == passcode
    }

    func isValid(duressPasscode: String) -> Bool {
        let duressLevel = currentPasscodeLevel + 1

        guard passcodes.count > duressLevel else {
            return false
        }

        return passcodes[duressLevel] == duressPasscode
    }

    func has(passcode: String) -> Bool {
        passcodes.contains(passcode)
    }

    func setLastPasscode() {
        guard !passcodes.isEmpty else {
            return
        }

        currentPasscodeLevel = passcodes.count - 1
        syncState()
    }

    func set(currentPasscode: String) {
        guard let level = passcodes.firstIndex(of: currentPasscode) else {
            return
        }

        guard currentPasscodeLevel != level else {
            return
        }

        currentPasscodeLevel = level
        syncState()
    }

    func set(passcode: String) throws {
        var newPasscodes = passcodes

        newPasscodes[currentPasscodeLevel] = passcode

        try save(passcodes: newPasscodes)
        passcodes = newPasscodes
        syncState()
    }

    func removePasscode() throws {
        var newPasscodes = passcodes

        newPasscodes[currentPasscodeLevel] = ""
        newPasscodes = Array(newPasscodes.prefix(currentPasscodeLevel + 1))

        try save(passcodes: newPasscodes)
        passcodes = newPasscodes
        syncState()
    }

    func set(duressPasscode: String) throws {
        var newPasscodes = passcodes

        if newPasscodes.count > currentPasscodeLevel + 1 {
            newPasscodes[currentPasscodeLevel + 1] = duressPasscode
        } else {
            newPasscodes.append(duressPasscode)
        }

        try save(passcodes: newPasscodes)
        passcodes = newPasscodes
        syncState()
    }

    func removeDuressPasscode() throws {
        var newPasscodes = passcodes

        newPasscodes = Array(newPasscodes.prefix(currentPasscodeLevel + 1))

        try save(passcodes: newPasscodes)
        passcodes = newPasscodes
        syncState()
    }
}
