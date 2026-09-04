import Combine

protocol IWCNLockProvider: AnyObject {
    var isLocked: Bool { get }
    var isLockedPublisher: AnyPublisher<Bool, Never> { get }
}

extension LockManager: IWCNLockProvider {
    var isLockedPublisher: AnyPublisher<Bool, Never> {
        $isLocked.eraseToAnyPublisher()
    }
}
