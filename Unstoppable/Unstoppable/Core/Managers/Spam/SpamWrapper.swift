import HsToolKit

class SpamWrapper {
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

    init(storage: ScannedTransactionStorage, contactBookManager: ContactBookManager, accountManager: AccountManager, logger _: Logger? = nil) {
        self.storage = storage
        self.contactBookManager = contactBookManager
        self.accountManager = accountManager
        logger = Logger(minLogLevel: .debug)
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
            .append(ZeroValueCondition(score: Self.zeroValueIncoming, logger: logger))
            .append(AddressSimilarityCondition(cache: outputCache, prefixScore: Self.addressPartScore, suffixScore: Self.addressPartScore, logger: logger))
            .append(LowAmountCondition(spamScore: Self.spamThreshold, riskScore: Self.amountRiskScore, dangerScore: Self.amountDangerScore, logger: logger))
            .append(TimeCorrelationCondition(blockScore: Self.correlationBlockScore, timeScore: Self.correlationTimeScore, logger: logger))

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
    func isSpam(address: String) -> Bool {
        (try? storage.findScanned(address: address))?.isSpam ?? false
    }
}
