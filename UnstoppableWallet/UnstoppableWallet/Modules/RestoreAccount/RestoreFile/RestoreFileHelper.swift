import Foundation

struct RestoreFileHelper {
    static func parse(url: URL) throws -> BackupModule.NamedSource {
        let data = try FileManager.default.contentsOfFile(coordinatingAccessAt: url)
        let filename = NSString(string: url.lastPathComponent).deletingPathExtension

        if let oneWallet = try? JSONDecoder().decode(WalletBackup.self, from: data) {
            return .init(name: filename, source: .wallet(oneWallet))
        }

        if let oneWalletV2 = try? JSONDecoder().decode(RestoreCloudModule.RestoredBackup.self, from: data) {
            return .init(name: oneWalletV2.name, source: .wallet(oneWalletV2.walletBackup))
        }

        if let fullBackup = try? JSONDecoder().decode(FullBackup.self, from: data) {
            return .init(name: filename, source: .full(fullBackup))
        }

        throw ParseError.wrongFile
    }

    static func resolve(name: String, elements: [String], checkRaw: Bool = false, style: String = "%d") -> String {
        let name: (String?) -> String = { [name, $0].compactMap { $0 }.joined(separator: " ") }

        if checkRaw {
            if !elements.contains(where: { $0.lowercased() == name(nil).lowercased() }) {
                return name(nil)
            }
        }

        for i in 1 ..< elements.count + 1 {
            let newName = name(style.localized(i))
            if !elements.contains(where: { $0.lowercased() == newName.lowercased() }) {
                return newName
            }
        }
        return name(style.localized(elements.count + 1))
    }
}

extension RestoreFileHelper {
    enum ParseError: Error {
        case wrongFile
    }
}
