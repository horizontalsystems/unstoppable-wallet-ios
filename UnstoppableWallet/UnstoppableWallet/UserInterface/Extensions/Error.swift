import Foundation

extension Error {

    var smartDescription: String {
        self is LocalizedError ? localizedDescription : "\(self)"
    }

}
