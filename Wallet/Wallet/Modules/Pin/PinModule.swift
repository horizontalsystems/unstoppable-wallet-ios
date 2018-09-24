import Foundation
import RxSwift

protocol IPinView: class {
    func highlightPinDot(at index: Int)
    func bind(pinLength: Int, title: String?, infoText: String?, infoFont: UIFont, infoAttachToTop: Bool)
    func onWrongPin(clean: Bool)
}

protocol IPinViewDelegate {
    func viewDidLoad()
    func onPinChange(pin: String?)
}

protocol IPinRouter {
    func onSet(pin: String)
    func onSetNew(pin: String)
    func onConfirm()
    func onUnlock()
    func onUnlockEdit()
}

protocol IPinInteractor {
    func viewDidLoad()
    func onPinChange(pin: String?)
}

protocol IPinInteractorDelegate: class {
    func bind(pinLength: Int)
    func highlightPinDot(index: Int)
    func onWrongPin(clean: Bool)
}
