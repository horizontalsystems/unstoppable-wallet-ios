import Foundation

struct RestoreFileHelper {
    static func parse(url: URL) throws -> BackupModule.NamedSource {
        let data = try FileManager.default.contentsOfFile(coordinatingAccessAt: url)
        let filename = NSString(string: url.lastPathComponent).deletingPathExtension

        if let oneWallet = try? JSONDecoder().decode(WalletBackup.self, from: data) {

            return .init(name: filename, source: .wallet(oneWallet))
        }

        if let fullBackup = try? JSONDecoder().decode(FullBackup.self, from: data) {

            return .init(name: filename, source: .full(fullBackup))
        }

        throw ParseError.wrongFile
    }

}

extension RestoreFileHelper {
    enum ParseError: Error {
        case wrongFile
    }
}
