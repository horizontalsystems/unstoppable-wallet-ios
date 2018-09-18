import Foundation

protocol INewPinInteractorDelegate: IPinInteractorDelegate {
    func onSet(pin: String)
}
