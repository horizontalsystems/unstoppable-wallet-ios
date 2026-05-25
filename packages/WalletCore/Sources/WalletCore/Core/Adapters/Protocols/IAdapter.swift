import Foundation

public protocol IAdapter: AnyObject {
    func start()
    func stop()
    func refresh()

    var statusInfo: [(String, Any)] { get }
    var debugInfo: String { get }
}
