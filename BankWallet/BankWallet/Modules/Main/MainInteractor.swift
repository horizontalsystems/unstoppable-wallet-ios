import Foundation

class MainInteractor {
    weak var delegate: IMainInteractorDelegate?
}

extension MainInteractor: IMainInteractor {
}
