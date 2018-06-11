import Foundation

class MainInteractor {
    weak var presenter: MainPresenterProtocol?
}

extension MainInteractor: MainPresenterDelegate {
}
