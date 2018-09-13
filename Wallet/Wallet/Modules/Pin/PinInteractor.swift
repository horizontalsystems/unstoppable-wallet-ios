import Foundation
import RxSwift
import WalletKit

class PinInteractor {
    weak var delegate: IPinInteractorDelegate?

    let pinLength = 6

    var pin: String?

    init() {
    }

}

extension PinInteractor: IPinInteractor {

    @objc func viewDidLoad() {
        delegate?.bind(pinLength: pinLength)
    }

    @objc func onPinChange(pin: String?) {
        guard let pin = pin, pin.count <= pinLength else {
            delegate?.onWrongPin()
            return
        }
        self.pin = pin
        delegate?.highlightPinDot(index: pin.count - 1)
    }

}
