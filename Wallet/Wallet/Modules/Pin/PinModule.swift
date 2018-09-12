import Foundation
import RxSwift

protocol IPinView: class {
    func highlightPinDot(at index: Int)
    func bind(pinLength: Int, title: String, infoText: String, infoFont: UIFont, infoAttachToTop: Bool)
}

protocol IPinViewDelegate {
    func viewDidLoad()
    func onPinChange(pin: String?)
}

protocol IPinRouter {
    func onSet(pin: String)
    func onConfirm()
}

protocol ISetPinInteractor {
    func viewDidLoad()
    func onPinChange(pin: String?)
}

protocol ISetPinInteractorDelegate: class {
    func bind(pinLength: Int)
    func highlightPinDot(index: Int)

    func onSet(pin: String)
    func onConfirm()
    func onWrongPin()
}
