import Foundation

protocol ISecureStorage: class {
    var words: [String]? { get }
    func set(words: [String]?) throws
    var pin: String? { get }
    func set(pin: String?) throws
}
