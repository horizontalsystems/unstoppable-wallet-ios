import Combine
import HsToolKit
import MarketKit

public class SpamWrapper {
    /// Total score >= 7: definite spam (.spam decision)
    private static let spamThreshold: Int = 7
    /// Total score >= 3 but < 7: likely spam (.suspicious decision)
    private static let suspiciousThreshold: Int = 3

    /// Incoming event with zero value — common in token approval exploits (+4)
    private static let zeroValueIncoming: Int = 4
    /// Incoming address matches prefix OR suffix of a cached outgoing address (+4 each, max +8)
    private static let addressPartScore: Int = 4
    /// Incoming amount below spam limit for the token — almost certainly spam (+7, instant spam)
    /// Note: equals spamThreshold, so this alone triggers .spam
    private static let amountRiskScore: Int = 3
    /// Incoming amount below danger limit — slightly suspicious (+2)
    private static let amountDangerScore: Int = 2
    /// Transaction within N blocks of a cached outgoing transaction (+4)
    private static let correlationBlockScore: Int = 4
    /// Transaction within N minutes of a cached outgoing transaction (+3)
    private static let correlationTimeScore: Int = 3

    private let storage: ScannedTransactionStorage
    private let contactBookManager: ContactBookManager
    private let accountManager: AccountManager
    private let logger: Logger?
    private var cancellables = Set<AnyCancellable>()

    public init(storage: ScannedTransactionStorage, contactBookManager: ContactBookManager, accountManager: AccountManager, localStorage: LocalStorage, logger _: Logger? = nil) {
        self.storage = storage
        self.contactBookManager = contactBookManager
        self.accountManager = accountManager
        logger = Logger(minLogLevel: .debug)

        // Update saved verdicts before contact changes trigger a history reload.
        contactBookManager.addressesAddedPublisher
            .sink { [weak self] addresses in
                try? self?.storage.markNotSpam(addresses: addresses)
            }
            .store(in: &cancellables)

        // Contacts saved before this cleanup existed are cleared once; later additions arrive as events
        if !localStorage.contactsSpamCleared, let contacts = contactBookManager.all,
           (try? storage.markNotSpam(addresses: contacts.flatMap(\.addresses).map(\.address))) != nil
        {
            localStorage.contactsSpamCleared = true
        }
    }

    func spamManager(source: TransactionSource) -> SpamManager? {
        guard let accountId = accountManager.activeAccount?.id else {
            return nil
        }

        let outputCache = OutputTransactionCache(storage: storage, logger: logger)

        let filterChain = SpamFilterChain(logger: logger)
            .append(ContactsFilter(contactManager: contactBookManager, logger: logger))
            .append(OutgoingPoisoningFilter(logger: logger))

        let evaluator = SpamScoreEvaluator(spamThreshold: Self.spamThreshold, suspiciousThreshold: Self.suspiciousThreshold, logger: logger)

        // Solana scores values per event (never a signed native aggregate) and has no zero-value
        // bonus: a zero coin transfer is instant spam there, so ZeroValueCondition would double-score.
        // Correlation is gated to the gray zone and matches 3 address characters, as on Android;
        // the other chains stay ungated, so they keep the stricter 4-character match
        if source.blockchainType == .solana {
            evaluator.append(GrayZoneGateCondition(
                value: SolanaLowAmountCondition(spamScore: Self.spamThreshold, riskScore: Self.amountRiskScore, dangerScore: Self.amountDangerScore, logger: logger),
                correlation: [
                    AddressSimilarityCondition(cache: outputCache, minMatchLength: 3, prefixScore: Self.addressPartScore, suffixScore: Self.addressPartScore, logger: logger),
                    TimeCorrelationCondition(cache: outputCache, blockScore: Self.correlationBlockScore, timeScore: Self.correlationTimeScore, logger: logger),
                ],
                spamThreshold: Self.spamThreshold
            ))
        } else if source.blockchainType == .near {
            // As on Android: a normal amount is trusted on its value alone, correlation only scores
            // the gray zone. Addresses compare on 2 characters, names being short
            evaluator.append(GrayZoneGateCondition(
                values: [
                    ZeroValueCondition(score: Self.zeroValueIncoming, logger: logger),
                    LowAmountCondition(spamScore: Self.spamThreshold, riskScore: Self.amountRiskScore, dangerScore: Self.amountDangerScore, logger: logger),
                ],
                correlation: [
                    AddressSimilarityCondition(cache: outputCache, minMatchLength: 2, normalize: Self.addressNormalizer(blockchainType: .near), prefixScore: Self.addressPartScore, suffixScore: Self.addressPartScore, logger: logger),
                    TimeCorrelationCondition(cache: outputCache, blockScore: Self.correlationBlockScore, timeScore: Self.correlationTimeScore, logger: logger),
                ],
                spamThreshold: Self.spamThreshold
            ))
        } else {
            evaluator
                .append(ZeroValueCondition(score: Self.zeroValueIncoming, logger: logger))
                .append(AddressSimilarityCondition(cache: outputCache, normalize: Self.addressNormalizer(blockchainType: source.blockchainType), prefixScore: Self.addressPartScore, suffixScore: Self.addressPartScore, logger: logger))
                .append(LowAmountCondition(spamScore: Self.spamThreshold, riskScore: Self.amountRiskScore, dangerScore: Self.amountDangerScore, logger: logger))
                .append(TimeCorrelationCondition(cache: outputCache, blockScore: Self.correlationBlockScore, timeScore: Self.correlationTimeScore, logger: logger))
        }

        return SpamManager(
            accountId: accountId,
            blockchainType: source.blockchainType,
            storage: storage,
            filterChain: filterChain,
            scoreEvaluator: evaluator,
            outputCache: outputCache,
            logger: logger
        )
    }
}

extension SpamWrapper {
    /// What a chain's addresses share, dropped before two addresses are compared for similarity; nil
    /// compares them as given.
    static func addressNormalizer(blockchainType: BlockchainType) -> ((String) -> String)? {
        if EvmBlockchainManager.blockchainTypes.contains(blockchainType) {
            return { $0.stripping(prefix: "0x") }
        }

        switch blockchainType {
        // "T" opens every 34-char Tron address and carries no more information than "0x"
        case .tron:
            return { $0.count == 34 && $0.hasPrefix("T") ? String($0.dropFirst()) : $0 }
        // a name drops its top-level account (".near", ".tg"), which every name under it shares
        case .near:
            return { address in
                if let dot = address.lastIndex(of: ".") {
                    return String(address[..<dot])
                }
                return address.stripping(prefix: "0x")
            }
        default:
            return nil
        }
    }
}

extension SpamWrapper {
    func isSpam(address: String) -> Bool {
        (try? storage.findScanned(address: address))?.isSpam ?? false
    }
}
