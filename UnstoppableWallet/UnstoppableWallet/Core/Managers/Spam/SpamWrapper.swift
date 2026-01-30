import HsToolKit

class SpamWrapper {
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

    func spamManager(source: TransactionSource) -> SpamManagerNew2? {
        guard let accountId = accountManager.activeAccount?.id else {
            return nil
        }

        let outputCache = OutputTransactionCache(logger: logger)

        let filterChain = SpamFilterChain(logger: logger)
            .append(ContactsFilter(contactManager: contactBookManager, logger: logger))
            .append(ZeroValueFilter(logger: logger))

        let scoreEvaluator = SpamScoreEvaluator(logger: logger)
            .append(ZeroValueCondition(logger: logger))
            .append(AddressSimilarityCondition(cache: outputCache, logger: logger))
            .append(LowAmountCondition(logger: logger))
            .append(TimeCorrelationCondition(logger: logger))

        return SpamManagerNew2(
            accountId: accountId,
            blockchainType: source.blockchainType,
            storage: storage,
            filterChain: filterChain,
            scoreEvaluator: scoreEvaluator,
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
