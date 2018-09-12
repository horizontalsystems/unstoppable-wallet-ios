import Foundation

protocol ISetPinInteractorDelegate: IPinInteractorDelegate {
    func onSet(pin: String)
}
