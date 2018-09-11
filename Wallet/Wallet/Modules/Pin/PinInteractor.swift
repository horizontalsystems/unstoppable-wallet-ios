import Foundation
import RxSwift
import WalletKit

class PinInteractor {

    weak var delegate: ISetPinInteractorDelegate?

    init() {
    }

}

extension PinInteractor: ISetPinInteractor {

}
