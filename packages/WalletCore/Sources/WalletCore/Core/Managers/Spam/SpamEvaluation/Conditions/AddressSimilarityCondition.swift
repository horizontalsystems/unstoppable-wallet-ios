import Foundation
import HsToolKit

final class AddressSimilarityCondition: SpamCondition {
    var identifier: String { "address_similarity" }

    private let cache: OutputTransactionCache
    private let minMatchLength: Int
    private let normalizer: ((String) -> String)?
    private let prefixScore: Int
    private let suffixScore: Int
    private let logger: Logger?

    init(
        cache: OutputTransactionCache,
        minMatchLength: Int = 4,
        normalize: ((String) -> String)? = nil,
        prefixScore: Int = 4,
        suffixScore: Int = 4,
        logger: Logger? = nil
    ) {
        self.cache = cache
        self.minMatchLength = minMatchLength
        normalizer = normalize
        self.prefixScore = prefixScore
        self.suffixScore = suffixScore
        self.logger = logger
    }

    func evaluate(_ context: SpamEvaluationContext) -> Int {
        let blockchainType = context.transaction.blockchainType
        let cachedOutputs = cache.get(blockchainType: blockchainType)

        guard !cachedOutputs.isEmpty else {
            return 0
        }

        guard !context.transaction.events.incoming.isEmpty else {
            return 0
        }

        let incomingAddresses = context.transaction.events.incoming.map(\.address)

        return bestMatch(incomingAddresses: incomingAddresses, cachedOutputs: cachedOutputs)
    }

    private func bestMatch(incomingAddresses: [String], cachedOutputs: [CachedOutputTransaction]) -> Int {
        var bestScore = 0
        let maxScore = prefixScore + suffixScore

        for incomingAddress in incomingAddresses {
            let normalizedIncoming = normalize(incomingAddress)

            for cached in cachedOutputs {
                // Skip if same address (legitimate return transaction). Only the full address counts:
                // two accounts the normalizer maps alike, such as `alice.near` and `alice.tg`, are a lookalike
                guard incomingAddress.lowercased() != cached.address.lowercased() else {
                    continue
                }

                let normalizedCached = normalize(cached.address)
                var score = 0

                if hasSimilarPrefix(normalizedIncoming, normalizedCached) {
                    score += prefixScore
                }

                if hasSimilarSuffix(normalizedIncoming, normalizedCached) {
                    score += suffixScore
                }

                if score > bestScore {
                    bestScore = score

                    if bestScore >= maxScore {
                        return bestScore
                    }
                }
            }
        }

        return bestScore
    }

    // what a chain's addresses share carries no information; the chain's normalizer drops it
    private func normalize(_ address: String) -> String {
        (normalizer?(address) ?? address).lowercased()
    }

    private func hasSimilarPrefix(_ address1: String, _ address2: String) -> Bool {
        address1.prefix(minMatchLength) == address2.prefix(minMatchLength)
    }

    private func hasSimilarSuffix(_ address1: String, _ address2: String) -> Bool {
        address1.suffix(minMatchLength) == address2.suffix(minMatchLength)
    }
}
