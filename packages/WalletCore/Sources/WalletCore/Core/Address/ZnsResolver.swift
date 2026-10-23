import Alamofire
import Foundation
import HsToolKit

/// Resolves Zcash Names (ZNS, https://www.zcashnames.com/docs) to unified addresses through the hosted Resolver.
///
/// Registrations are Name Notes on chain, readable by anyone with the registry's published viewing key. The Resolver
/// is checked to report that registry (`status.viewing_key`, as the ZNS SDK's `verify()` does). That catches a wrong
/// endpoint, not a dishonest one: records are not re-derived from the chain here, so the Resolver is trusted.
class ZnsResolver {
    static let mainnetUrl = "https://main.zcashnames.com"

    /// Full viewing key of the mainnet registry (zcashnames.com/docs/resolver/verifying-state)
    static let mainnetViewingKey = "uview1209ld9y4fr2sel9q87kfjg7xm2sy53e3qf7dvcw3w8jwhhjpldl8z0vk0a6hveg4jk7xcn0rc9mr8yg77djfpc0uxrm5pqzt8q7ul4w0nvs3x5q9vmk9nm2crywtqaealek4mp47ur7ywu7g4g4xcdlwv6gnqzvu5panv5je2ps6rxmx4856unlt5wde8fpz8uhrqchmwhn2j252h3cyx5phad877xezerm6ex8l5kcfjw02ll7m0nspfufamh3ae9ea48395elptspnv6vvc70j2gcjrdze9syt8kpr2kc67flvg8687thdkpha7lpt9r4p9wjty90q2v2yjanqsr2zrecrqs7lfx9cpkmshf7jyh2vvwfqnyzwtpuy7p72hm2mjhperdafvm9u5rwa6s6urcy0uw30f687e3jnmas45qfqtwyz39kf6kxklfrdn7t4hkz56jegmlr8s8hwmt9wa8vz8zlmm76lrmzyj82nzpeqfu572njq"

    // the send screen waits on the lookup; a dead Resolver must not hold it for the session's default minute
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
    /// Throws when the Resolver is unreachable, errors, does not serve the mainnet registry, or the record does not
    /// answer the query.
    func resolve(name: String) async throws -> String? {
        async let statusJson = call(method: "status", params: [:])
        async let resolveJson = call(method: "resolve", params: ["query": name])

        try await Self.verifyRegistry(json: statusJson)

        guard let registration = try await Self.registration(json: resolveJson) else {
            return nil
        }

        return try Self.validate(name: name, registration: registration)
    }

    private func call(method: String, params: [String: Any]) async throws -> Any {
        let parameters: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params,
        ]

        return try await networkManager.fetchJson(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, interceptor: Self.timeoutInterceptor)
    }
}

extension ZnsResolver {
    struct Registration {
        let name: String
        let address: String
    }

    enum ResolveError: Error {
        case rpcError(code: Int?, message: String?)
        case malformedResponse
        case unknownRegistry
        case nameMismatch
    }

    /// Checks the body of a `status` call: the Resolver must scan the mainnet registry.
    static func verifyRegistry(json: Any, viewingKey: String = ZnsResolver.mainnetViewingKey) throws {
        guard let object = try result(json: json) as? [String: Any], let reported = object["viewing_key"] as? String else {
            throw ResolveError.malformedResponse
        }

        guard reported == viewingKey else {
            throw ResolveError.unknownRegistry
        }
    }

    /// Parses the body of a `resolve` call made with a name query: nil when `result` is null (not registered).
    static func registration(json: Any) throws -> Registration? {
        let result = try result(json: json)

        if result is NSNull {
            return nil
        }

        // an address query answers with an array; only a name query is ever sent
        guard let object = result as? [String: Any],
              let name = object["name"] as? String,
              let address = object["address"] as? String
        else {
            throw ResolveError.malformedResponse
        }

        return Registration(name: name, address: address)
    }

    /// Checks that `registration` answers the query for `name`. Its `expires_at` is not checked: a lapsed name keeps
    /// resolving to its owner until the Mint's release lands on chain, and then the Resolver answers null.
    static func validate(name: String, registration: Registration) throws -> String {
        guard Array(registration.name.utf8) == Array(name.utf8) else {
            throw ResolveError.nameMismatch
        }

        return registration.address
    }

    private static func result(json: Any) throws -> Any {
        guard let response = json as? [String: Any] else {
            throw ResolveError.malformedResponse
        }

        if let error = response["error"] as? [String: Any] {
            throw ResolveError.rpcError(code: error["code"] as? Int, message: error["message"] as? String)
        }

        guard let result = response["result"] else {
            throw ResolveError.malformedResponse
        }

        return result
    }
}
