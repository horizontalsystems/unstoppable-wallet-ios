import Foundation

class Singletons {
    static let shared = Singletons()

    let configuration: Configuration
    let realmFactory: RealmFactory
    let peerGroup: PeerGroup
    let syncer: Syncer
    let factory: Factory

    let difficultyEncoder: DifficultyEncoder
    let difficultyCalculator: DifficultyCalculator

    let blockValidator: BlockValidator
    let blockSaver: BlockSaver

    let headerSyncer: HeaderSyncer
    let headerHandler: HeaderHandler

    let blockSyncer: BlockSyncer
    let merkleBlockValidator: MerkleBlockValidator
    let merkleBlockHandler: MerkleBlockHandler

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
        factory = Factory()

        difficultyEncoder = DifficultyEncoder()
        difficultyCalculator = DifficultyCalculator(difficultyEncoder: difficultyEncoder)

        blockValidator = TestNetBlockValidator(calculator: difficultyCalculator)
        blockSaver = BlockSaver(realmFactory: realmFactory)

        headerSyncer = HeaderSyncer(realmFactory: realmFactory, peerGroup: peerGroup, configuration: configuration)
        headerHandler = HeaderHandler(realmFactory: realmFactory, factory: factory, validator: blockValidator, saver: blockSaver, configuration: configuration)

        blockSyncer = BlockSyncer(realmFactory: realmFactory, peerGroup: peerGroup)
        merkleBlockValidator = MerkleBlockValidator()
        merkleBlockHandler = MerkleBlockHandler(realmFactory: realmFactory, validator: merkleBlockValidator, saver: blockSaver)

        transactionExtractor = TransactionExtractor()
        transactionSaver = TransactionSaver(realmFactory: realmFactory)
        transactionLinker = TransactionLinker(realmFactory: realmFactory)
        transactionHandler = TransactionHandler(realmFactory: realmFactory, extractor: transactionExtractor, saver: transactionSaver, linker: transactionLinker)

        inputSigner = InputSigner(realmFactory: realmFactory, walletKitManager: WalletKitManager.shared)
        scriptBuilder = ScriptBuilder()
        unspentOutputsManager = UnspentOutputsManager(realmFactory: realmFactory)

        peerGroup.delegate = syncer

        syncer.headerSyncer = headerSyncer
        syncer.headerHandler = headerHandler
        syncer.merkleBlockHandler = merkleBlockHandler
        syncer.transactionHandler = transactionHandler
    }

}
