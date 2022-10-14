import Foundation

class RestorePrivateKeyService {
}

extension RestorePrivateKeyService {

    func accountType(text: String) throws -> AccountType {
        guard !text.isEmpty else {
            throw RestoreError.emptyText
        }

        //  todo

        throw RestoreError.invalidText
    }

}

extension RestorePrivateKeyService {

    enum RestoreError: Error {
        case emptyText
        case invalidText
    }

}
