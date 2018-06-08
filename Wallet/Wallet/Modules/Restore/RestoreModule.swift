import Foundation

protocol RestoreViewDelegate {
    func cancelDidTap()
}

protocol RestoreViewProtocol: class {
}

protocol RestorePresenterDelegate {
}

protocol RestorePresenterProtocol: class {
}

protocol RestoreRouterProtocol {
    func close()
}
