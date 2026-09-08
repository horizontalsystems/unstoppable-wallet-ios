import Combine

protocol IWCLockProvider: AnyObject {
    var isLocked: Bool { get }
    var isLockedPublisher: AnyPublisher<Bool, Never> { get }
}

extension LockManager: IWCLockProvider {
    var isLockedPublisher: AnyPublisher<Bool, Never> {
        $isLocked.eraseToAnyPublisher()
    }
}
