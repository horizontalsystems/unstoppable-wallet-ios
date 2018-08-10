import Foundation

class Factory {
    static let shared = Factory()

    let configuration: Configuration
    let realmFactory: RealmFactory
    let peerGroup: PeerGroup
    let syncer: Syncer

    let difficultyEncoder: DifficultyEncoder
    let difficultyCalculator: DifficultyCalculator

    let blockFactory: BlockFactory
    let blockValidator: BlockValidator
    let blockSaver: BlockSaver

    let headerSyncer: HeaderSyncer
    let headerHandler: HeaderHandler

    let blockSyncer: BlockSyncer
    let merkleBlockValidator: MerkleBlockValidator
    let merkleBlockHandler: MerkleBlockHandler

    let transactionFactory: TransactionFactory
    let transactionExtractor: TransactionExtractor
    let transactionSaver: TransactionSaver
    let transactionLinker: TransactionLinker
    let transactionHandler: TransactionHandler

    let inputSigner: InputSigner
    let scriptBuilder: ScriptBuilder
    let unspentOutputsManager: UnspentOutputsManager

    init() {
        configuration = Configuration()
        realmFactory = RealmFactory()
        peerGroup = PeerGroup()
        syncer = Syncer()

        difficultyEncoder = DifficultyEncoder()
        difficultyCalculator = DifficultyCalculator(difficultyEncoder: difficultyEncoder)

        blockFactory = BlockFactory()
        blockValidator = TestNetBlockValidator(calculator: difficultyCalculator)
        blockSaver = BlockSaver(realmFactory: realmFactory)

        headerSyncer = HeaderSyncer(realmFactory: realmFactory, peerGroup: peerGroup, configuration: configuration)
        headerHandler = HeaderHandler(realmFactory: realmFactory, blockFactory: blockFactory, validator: blockValidator, saver: blockSaver, configuration: configuration)

        blockSyncer = BlockSyncer(realmFactory: realmFactory, peerGroup: peerGroup)
        merkleBlockValidator = MerkleBlockValidator()
        merkleBlockHandler = MerkleBlockHandler(realmFactory: realmFactory, validator: merkleBlockValidator, saver: blockSaver)

        transactionExtractor = TransactionExtractor()
        transactionSaver = TransactionSaver(realmFactory: realmFactory)
        transactionLinker = TransactionLinker(realmFactory: realmFactory)
        transactionHandler = TransactionHandler(realmFactory: realmFactory, extractor: transactionExtractor, saver: transactionSaver, linker: transactionLinker)

        inputSigner = InputSigner(realmFactory: realmFactory, walletKitManager: WalletKitManager.shared)
        scriptBuilder = ScriptBuilder()
        transactionFactory = TransactionFactory()
        unspentOutputsManager = UnspentOutputsManager(realmFactory: realmFactory)

        peerGroup.delegate = syncer

        syncer.headerSyncer = headerSyncer
        syncer.headerHandler = headerHandler
        syncer.merkleBlockHandler = merkleBlockHandler
        syncer.transactionHandler = transactionHandler
    }

}
