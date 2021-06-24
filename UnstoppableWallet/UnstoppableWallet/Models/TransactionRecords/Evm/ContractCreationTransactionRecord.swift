class ContractCreationTransactionRecord: EvmTransactionRecord {

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        .contractCreation
    }

}
