import Foundation
import RxSwift
import WalletKit

class PinInteractor {
    weak var delegate: ISetPinInteractorDelegate?

    let pinLength = 4

    var pin: String?

    init() {
    }

}

extension PinInteractor: ISetPinInteractor {

    @objc func viewDidLoad() {
        delegate?.bind(pinLength: pinLength)
    }

    @objc func onPinChange(pin: String?) {
        guard let pin = pin, pin.count <= pinLength else {
            return
        }
        self.pin = pin
        delegate?.highlightPinDot(index: pin.count - 1)
    }

}
