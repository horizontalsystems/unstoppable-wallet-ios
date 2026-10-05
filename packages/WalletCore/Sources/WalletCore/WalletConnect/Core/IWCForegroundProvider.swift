import Combine

protocol IWCForegroundProvider: AnyObject {
    var isActive: Bool { get }
    var isActivePublisher: AnyPublisher<Bool, Never> { get }
}

extension AppManager: IWCForegroundProvider {}
