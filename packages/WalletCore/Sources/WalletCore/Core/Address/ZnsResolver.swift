import Alamofire
import CryptoKit
import Foundation
import HsToolKit

/// Resolves Zcash Names (ZNS, https://www.zcashnames.com/docs) to unified addresses through the hosted indexer
/// (Android `ZnsResolver`).
///
/// Every registration carries an Ed25519 signature of the registrar, checked against the pinned key before the
/// address is used, so the indexer cannot bind a name to an address the registrar never signed. It can still serve
/// an older signed binding of the same name: CLAIM and BUY signatures carry no nonce.
class ZnsResolver {
    static let mainnetUrl = "https://main.zcashnames.com"

    /// Ed25519 public key of the ZNS registrar (zcashme/ZNS README, the indexer's `status.admin_pubkey`)
    static let adminKey = try! Curve25519.Signing.PublicKey(rawRepresentation: Data(base64Encoded: "zobrGyAwpM3mtC0Vo4UOk0bc9Ygg0gdDeD8dCQAOXI4=")!)

    /// How far below the reported nonce `verify` searches for the nonce an UPDATE was signed with
    static let nonceSearchDepth: Int64 = 64

    private static let signatureSize = 64

    // the send screen waits on the lookup; a dead indexer must not hold it for the session's default minute
    private static let timeoutInterceptor = Adapter { request, _, completion in
        var request = request
        request.timeoutInterval = 5
        completion(.success(request))
    }

    private let networkManager: NetworkManager
    private let url: String

    init(networkManager: NetworkManager, url: String = ZnsResolver.mainnetUrl) {
        self.networkManager = networkManager
        self.url = url
    }

    /// Returns the unified address bound to a normalized `name`, or nil when the name is not registered.
    /// Throws when the indexer is unreachable or answers with an error, or when the registration does not verify.
    func resolve(name: String) async throws -> String? {
        let parameters: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "resolve",
            "params": ["query": name],
        ]

        let json = try await networkManager.fetchJson(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, interceptor: Self.timeoutInterceptor)

        guard let registration = try Self.registration(json: json) else {
            return nil
        }

        return try Self.validate(name: name, registration: registration)
    }
}

extension ZnsResolver {
    struct Registration {
        let name: String
        let address: String
        let nonce: Int64
        let lastAction: String
        let signature: String?
        let pubkey: String?
    }

    enum ResolveError: Error {
        case rpcError(code: Int?, message: String?)
        case malformedResponse
        case nameMismatch
        case invalidSignature
    }

    /// Parses the body of a `resolve` call made with a name query: nil when `result` is null (not registered).
    static func registration(json: Any) throws -> Registration? {
        guard let response = json as? [String: Any] else {
            throw ResolveError.malformedResponse
        }

        if let error = response["error"] as? [String: Any] {
            throw ResolveError.rpcError(code: error["code"] as? Int, message: error["message"] as? String)
        }

        guard let result = response["result"] else {
            throw ResolveError.malformedResponse
        }

        if result is NSNull {
            return nil
        }

        // an address query answers with an array; only a name query is ever sent
        guard let object = result as? [String: Any],
              let name = object["name"] as? String,
              let address = object["address"] as? String,
              let lastAction = object["last_action"] as? String,
              let nonce = parseNonce(object["nonce"])
        else {
            throw ResolveError.malformedResponse
        }

        return Registration(
            name: name,
            address: address,
            nonce: nonce,
            lastAction: lastAction,
            signature: object["signature"] as? String,
            pubkey: object["pubkey"] as? String
        )
    }

    /// Checks that `registration` answers the query for `name` and carries a registrar signature over its address.
    static func validate(name: String, registration: Registration, adminKey: Curve25519.Signing.PublicKey = ZnsResolver.adminKey) throws -> String {
        guard Array(registration.name.utf8) == Array(name.utf8) else {
            throw ResolveError.nameMismatch
        }

        guard verify(registration: registration, adminKey: adminKey) else {
            throw ResolveError.invalidSignature
        }

        return registration.address
    }

    /// The pre-image the registrar signed, by `last_action`. Only actions whose pre-image covers the address are
    /// accepted: a DELIST signs `DELIST:{name}:{nonce}`, which says nothing about the address it comes with.
    static func preImage(registration: Registration, nonce: Int64) -> String? {
        switch registration.lastAction {
        case "CLAIM": return "CLAIM:\(registration.name):\(registration.address)"
        case "BUY": return "BUY:\(registration.name):\(registration.address)"
        case "UPDATE": return "UPDATE:\(registration.name):\(registration.address):\(nonce)"
        default: return nil
        }
    }

    /// Verifies the registrar's signature binding the registration's name to its address.
    ///
    /// Only admin-signed registrations are accepted: a sovereign one carries the owner's key in `pubkey`, and nothing
    /// the registrar signed vouches for that key.
    ///
    /// The reported nonce is the registry's current value, and a later LIST raises it without re-signing the UPDATE,
    /// so the UPDATE pre-image is tried from the reported nonce down, at most `nonceSearchDepth` steps. Any match
    /// still proves the registrar signed this exact name-to-address binding.
    static func verify(registration: Registration, adminKey: Curve25519.Signing.PublicKey = ZnsResolver.adminKey) -> Bool {
        guard registration.pubkey == nil,
              registration.nonce >= 0,
              let encodedSignature = registration.signature,
              let signature = Data(base64Encoded: encodedSignature),
              signature.count == signatureSize
        else {
            return false
        }

        let lowestNonce = registration.lastAction == "UPDATE" ? max(0, registration.nonce - nonceSearchDepth) : registration.nonce

        for nonce in stride(from: registration.nonce, through: lowestNonce, by: -1) {
            // a name or address outside ASCII is not something the registrar signs
            guard let message = preImage(registration: registration, nonce: nonce)?.data(using: .ascii) else {
                return false
            }

            if adminKey.isValidSignature(signature, for: message) {
                return true
            }
        }

        return false
    }

    // a whole non-negative number; the indexer controls it, so nothing it sends may overflow the nonce walk
    private static func parseNonce(_ value: Any?) -> Int64? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(), let nonce = number as? Int64, nonce >= 0 else {
            return nil
        }

        return nonce
    }
}
