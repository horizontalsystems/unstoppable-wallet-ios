import Foundation
import HsToolKit

class OpenCryptoPaySubmitter {
    private let provider: OpenCryptoPayProvider

    init(provider: OpenCryptoPayProvider) {
        self.provider = provider
    }

    // One-shot: a single submit attempt. All retrying is the worker's job (OpenCryptoPayProofWorker).
    func submit(callback: URL, quote: String, method: String, proof: OpenCryptoPayProof) async throws {
        try await provider.submitProof(callback: callback, quote: quote, method: method, proof: proof)
    }
}

enum OpenCryptoPaySubmitError {
    static func isTerminal(_ error: Error) -> Bool {
        guard let responseError = error as? NetworkManager.ResponseError,
              let status = responseError.statusCode
        else {
            return false
        }
        // 429 (rate-limit) and 408 (timeout) are retryable, not terminal.
        return (400 ..< 500).contains(status) && status != 429 && status != 408
    }
}
