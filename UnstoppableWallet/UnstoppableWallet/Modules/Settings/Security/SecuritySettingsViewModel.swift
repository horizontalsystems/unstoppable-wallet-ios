import Combine
import ComponentKit
import PinKit
import SwiftUI

class SecuritySettingsViewModel: ObservableObject {
    private let pinKit: PinKit.Kit
    private var cancellables = Set<AnyCancellable>()

    @Published var passcodeEnabled: Bool = false {
        didSet {
            passcodeSwitchOn = passcodeEnabled
        }
    }

    @Published var passcodeSwitchOn: Bool = false {
        didSet {
            guard oldValue != passcodeSwitchOn else {
                return
            }

            if passcodeSwitchOn {
                if !passcodeEnabled {
                    setPasscodePresented = true
                }
            } else {
                if passcodeEnabled {
                    unlockPasscodePresented = true
                }
            }
        }
    }

    @Published var setPasscodePresented: Bool = false
    @Published var unlockPasscodePresented: Bool = false

    @Published var biometryEnabled: Bool = false {
        didSet {
            if pinKit.biometryEnabled != biometryEnabled {
                pinKit.biometryEnabled = biometryEnabled
            }
        }
    }

    @Published var biometryAvailable: Bool = true

    var biometryTitle: String = ""
    var biometryIconName: String = ""

    init(pinKit: PinKit.Kit) {
        self.pinKit = pinKit

        pinKit.isPinSetPublisher
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        pinKit.biometryTypePublisher
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)

        sync()
    }

    private func sync() {
        passcodeEnabled = pinKit.isPinSet
        biometryEnabled = pinKit.biometryEnabled

        switch pinKit.biometryType {
            case .faceId:
                biometryAvailable = true
                biometryTitle = "settings_security.face_id".localized
                biometryIconName = "face_id_24"
            case .touchId:
                biometryAvailable = true
                biometryTitle = "settings_security.touch_id".localized
                biometryIconName = "touch_id_2_24"
            default:
                biometryAvailable = false
                biometryTitle = ""
                biometryIconName = ""
        }
    }
}

extension SecuritySettingsViewModel {
    func onUnlock() {
        do {
            try pinKit.clear()
        } catch {
            HudHelper.instance.show(banner: .error(string: error.smartDescription))
        }
    }

    func cancelSetPasscode() {
        if !passcodeEnabled {
            passcodeSwitchOn = false
        }
    }

    func cancelUnlock() {
        if passcodeEnabled {
            passcodeSwitchOn = true
        }
    }
}
