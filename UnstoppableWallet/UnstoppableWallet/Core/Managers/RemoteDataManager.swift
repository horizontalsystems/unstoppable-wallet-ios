import Foundation

protocol IRemoteDataManager {
    associatedtype T

    func checkAvailable() async throws
    func getAll() async throws -> [T]
    func save(item: T) async throws
    func delete(uid: Data) async throws -> T
}

class CloudAccountBackupManager {

}

extension CloudAccountBackupManager {

    func backedUp(accountId: Data) async throws -> Bool {
        false
    }

    var existFilenames: [String] {
        []
    }

}

extension CloudAccountBackupManager: IRemoteDataManager {

    func checkAvailable() async throws {

    }

    func getAll() async throws -> [Account] {
        fatalError("getAll() has not been implemented")
    }

    func save(item: Account) async throws {
    }

    func delete(uid: Data) async throws -> Account {
        fatalError("delete(uid:) has not been implemented")
    }

}
