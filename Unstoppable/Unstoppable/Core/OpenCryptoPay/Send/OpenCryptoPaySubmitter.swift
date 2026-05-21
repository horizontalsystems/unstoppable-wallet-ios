import Foundation
import HsToolKit

class OpenCryptoPaySubmitter {
    private let provider: OpenCryptoPayProvider
    private let maxAttempts = 3
    private let backoffSeconds: [TimeInterval] = [1, 3, 9]

    init(provider: OpenCryptoPayProvider) {
        self.provider = provider
    }

    func submit(callback: URL, quote: String, method: String, proof: OpenCryptoPayProof) async throws {
        var lastError: Error?

        for attempt in 0 ..< maxAttempts {
            do {
                try await provider.submitProof(callback: callback, quote: quote, method: method, proof: proof)
                return
            } catch {
                lastError = error

                // 4xx — terminal (bad quote / expired / malformed). No retry.
                if Self.isTerminal(error: error) {
                    throw error
                }

                if attempt + 1 < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(backoffSeconds[attempt] * 1_000_000_000))
                }
            }
        }

        throw lastError ?? OpenCryptoPayManager.Error.network(NSError(domain: "ocp.submit", code: -1))
    }

    private static func isTerminal(error: Error) -> Bool {
        guard let responseError = error as? NetworkManager.ResponseError,
              let status = responseError.statusCode
        else {
            return false
        }
        return (400 ..< 500).contains(status)
    }
}
