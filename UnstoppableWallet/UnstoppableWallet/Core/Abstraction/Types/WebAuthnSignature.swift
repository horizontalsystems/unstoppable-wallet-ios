import Foundation

public struct WebAuthnSignature: Equatable, Hashable {
    public let authenticatorData: Data
    public let clientDataJSON: Data
    public let signature: Data

    public init(authenticatorData: Data, clientDataJSON: Data, signature: Data) {
        self.authenticatorData = authenticatorData
        self.clientDataJSON = clientDataJSON
        self.signature = signature
    }
}
