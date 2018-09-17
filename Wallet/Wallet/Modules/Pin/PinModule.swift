import Foundation
import RxSwift

protocol IPinView: class {
    func highlightPinDot(at index: Int)
    func bind(pinLength: Int, title: String?, infoText: String, infoFont: UIFont, infoAttachToTop: Bool)
    func onWrongPin()
}

protocol IPinViewDelegate {
    func viewDidLoad()
    func onPinChange(pin: String?)
}

protocol IPinRouter {
    func onSet(pin: String)
    func onConfirm()
}

protocol IPinInteractor {
    func viewDidLoad()
    func onPinChange(pin: String?)
}

protocol IPinInteractorDelegate: class {
    func bind(pinLength: Int)
    func highlightPinDot(index: Int)
    func onWrongPin()
}
