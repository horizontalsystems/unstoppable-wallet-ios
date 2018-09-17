import Foundation

protocol IEditPinInteractorDelegate: IPinInteractorDelegate {
    func onSet(pin: String)
}
