import Foundation

public struct Passkey {
    public let credentialID: Data
    public let name: String
    public let mnemonic: [String]

    public init(credentialID: Data, name: String, mnemonic: [String]) {
        self.credentialID = credentialID
        self.name = name
        self.mnemonic = mnemonic
    }
}
