/// Describes the plugin's transaction records for the generic list, info, rate and spam code.
protocol TransactionPresentationCapability: BlockchainPlugin {
    /// nil when the record is not the plugin's. Pure and cheap; called on any thread.
    func summary(record: TransactionRecord) -> TransactionSummary?
}
