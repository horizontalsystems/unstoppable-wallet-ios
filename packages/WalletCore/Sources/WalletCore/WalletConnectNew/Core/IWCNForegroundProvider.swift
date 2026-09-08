import Combine

protocol IWCNForegroundProvider: AnyObject {
    var isActive: Bool { get }
    var isActivePublisher: AnyPublisher<Bool, Never> { get }
}

extension AppManager: IWCNForegroundProvider {}
