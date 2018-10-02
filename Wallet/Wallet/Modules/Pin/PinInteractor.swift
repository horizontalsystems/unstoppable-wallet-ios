import Foundation

class PinInteractor {
    weak var delegate: IPinInteractorDelegate?

    private let pinManager: PinManager
    private var storedPin: String?

    init(pinManager: PinManager) {
        self.pinManager = pinManager
    }

}

extension PinInteractor: IPinInteractor {

    func set(pin: String?) {
        storedPin = pin
    }

    func validate(pin: String) -> Bool {
        return storedPin == pin
    }

    func save(pin: String) {
        do {
            try pinManager.store(pin: pin)
            delegate?.didSavePin()
        } catch {
            delegate?.didFailToSavePin()
        }
    }

    func unlock(with pin: String) -> Bool {
        return pinManager.validate(pin: pin)
    }

}
