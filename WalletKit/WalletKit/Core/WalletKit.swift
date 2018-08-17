import Foundation
import RealmSwift

public class WalletKit {
    let configuration: Configuration
    let realmFactory: RealmFactory
    let logger: Logger

    let hdWallet: HDWallet

    let peerGroup: PeerGroup
    let syncer: Syncer
    let factory: Factory

    let difficultyEncoder: DifficultyEncoder
    let difficultyCalculator: DifficultyCalculator

    let blockValidator: BlockValidator

    let headerSyncer: HeaderSyncer
    let headerHandler: HeaderHandler

    let blockSyncer: BlockSyncer
    let merkleBlockValidator: MerkleBlockValidator

    let addressConverter: AddressConverter
    let transactionProcessor: TransactionProcessor
    let transactionExtractor: TransactionExtractor
    let transactionLinker: TransactionLinker
    let transactionHandler: TransactionHandler
    let transactionSender: TransactionSender
    let transactionCreator: TransactionCreator
    let transactionBuilder: TransactionBuilder

    let inputSigner: InputSigner
    let scriptBuilder: ScriptBuilder
    let unspentOutputSelector: UnspentOutputSelector
    let unspentOutputProvider: UnspentOutputProvider

    public init(withWords words: [String], realmConfiguration: Realm.Configuration) {
        configuration = Configuration()
        realmFactory = RealmFactory(configuration: realmConfiguration)
        logger = Logger()

        hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), network: configuration.network)

        peerGroup = PeerGroup(realmFactory: realmFactory)
        syncer = Syncer(logger: logger, realmFactory: realmFactory)
        factory = Factory()

        difficultyEncoder = DifficultyEncoder()
        difficultyCalculator = DifficultyCalculator(difficultyEncoder: difficultyEncoder)

        blockValidator = TestNetBlockValidator(calculator: difficultyCalculator)

        headerSyncer = HeaderSyncer(realmFactory: realmFactory, peerGroup: peerGroup, configuration: configuration)
        headerHandler = HeaderHandler(realmFactory: realmFactory, factory: factory, validator: blockValidator, configuration: configuration)

        blockSyncer = BlockSyncer(realmFactory: realmFactory, peerGroup: peerGroup)
        merkleBlockValidator = MerkleBlockValidator()

        inputSigner = InputSigner(hdWallet: hdWallet)
        scriptBuilder = ScriptBuilder()

        unspentOutputSelector = UnspentOutputSelector()
        unspentOutputProvider = UnspentOutputProvider(realmFactory: realmFactory)

        addressConverter = AddressConverter(network: configuration.network)
        transactionExtractor = TransactionExtractor(addressConverter: addressConverter)
        transactionLinker = TransactionLinker()
        transactionProcessor = TransactionProcessor(realmFactory: realmFactory, extractor: transactionExtractor, linker: transactionLinker, logger: logger)
        transactionHandler = TransactionHandler(realmFactory: realmFactory, processor: transactionProcessor)
        transactionSender = TransactionSender(realmFactory: realmFactory, peerGroup: peerGroup)
        transactionBuilder = TransactionBuilder(unspentOutputSelector: unspentOutputSelector, unspentOutputProvider: unspentOutputProvider, addressConverter: addressConverter, inputSigner: inputSigner, scriptBuilder: scriptBuilder, factory: factory)
        transactionCreator = TransactionCreator(realmFactory: realmFactory, transactionBuilder: transactionBuilder)

        peerGroup.delegate = syncer

        syncer.headerSyncer = headerSyncer
        syncer.headerHandler = headerHandler
        syncer.transactionHandler = transactionHandler

        preFillInitialTestData()
    }

    public func showRealmInfo() {
        let realm = realmFactory.realm

        let blockCount = realm.objects(Block.self).count
        let pubKeysCount = realm.objects(PublicKey.self).count

        print("BLOCK COUNT: \(blockCount)")
        if let block = realm.objects(Block.self).first {
            print("First Block: \(block.height) --- \(block.reversedHeaderHashHex)")
        }
        if let block = realm.objects(Block.self).last {
            print("Last Block: \(block.height) --- \(block.reversedHeaderHashHex)")
        }

        print("PUBLIC KEYS COUNT: \(pubKeysCount)")
        if let pubKey = realm.objects(PublicKey.self).first {
            print("First PublicKey: \(pubKey.index) --- \(pubKey.external) --- \(pubKey.address)")
        }
        if let pubKey = realm.objects(PublicKey.self).last {
            print("Last PublicKey: \(pubKey.index) --- \(pubKey.external) --- \(pubKey.address)")
        }
    }

    public func start() throws {
        peerGroup.connect()
    }

    public var transactionsRealmResults: Results<Transaction> {
        return realmFactory.realm.objects(Transaction.self).filter("isMine = %@", true)
    }

    public func send(to address: String, value: Int) throws {
        try transactionCreator.create(to: address, value: value)
    }

    private func preFillInitialTestData() {
        let realm = realmFactory.realm

        var pubKeys = [PublicKey]()

        for i in 0..<10 {
            if let pubKey = try? hdWallet.receivePublicKey(index: i) {
                pubKeys.append(pubKey)
            }
            if let pubKey = try? hdWallet.changePublicKey(index: i) {
                pubKeys.append(pubKey)
            }
        }

        try? realm.write {
            realm.add(pubKeys, update: true)
        }
    }

}
