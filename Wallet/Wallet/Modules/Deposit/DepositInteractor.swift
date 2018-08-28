import Foundation

class DepositInteractor {

    weak var delegate: IDepositInteractorDelegate?

    private let adapters: [IAdapter]

    init(adapters: [IAdapter]) {
        self.adapters = adapters
    }

}

extension DepositInteractor: IDepositInteractor {

}
