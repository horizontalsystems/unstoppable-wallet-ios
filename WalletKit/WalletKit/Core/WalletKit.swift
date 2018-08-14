import Foundation
import RealmSwift

public class WalletKit {
    let configuration: Configuration
    let realmFactory: RealmFactory

    let hdWallet: HDWallet

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

    let addressConverter: AddressConverter
    let transactionExtractor: TransactionExtractor
    let transactionSaver: TransactionSaver
    let transactionLinker: TransactionLinker
    let transactionHandler: TransactionHandler
    let transactionSender: TransactionSender

    let inputSigner: InputSigner
    let scriptBuilder: ScriptBuilder
    let unspentOutputSelector: UnspentOutputSelector

    public init(withWords words: [String], realmConfiguration: Realm.Configuration) {
        configuration = Configuration()
        realmFactory = RealmFactory(configuration: realmConfiguration)

        hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), network: configuration.network)

        peerGroup = PeerGroup(realmFactory: realmFactory)
        syncer = Syncer(realmFactory: realmFactory)
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

        addressConverter = AddressConverter(network: configuration.network)
        transactionExtractor = TransactionExtractor(addressConverter: addressConverter)
        transactionSaver = TransactionSaver(realmFactory: realmFactory)
        transactionLinker = TransactionLinker(realmFactory: realmFactory)
        transactionHandler = TransactionHandler(realmFactory: realmFactory, extractor: transactionExtractor, saver: transactionSaver, linker: transactionLinker)
        transactionSender = TransactionSender(realmFactory: realmFactory, peerGroup: peerGroup)

        inputSigner = InputSigner(hdWallet: hdWallet)
        scriptBuilder = ScriptBuilder()
        unspentOutputSelector = UnspentOutputSelector()

        peerGroup.delegate = syncer

        syncer.headerSyncer = headerSyncer
        syncer.headerHandler = headerHandler
        syncer.merkleBlockHandler = merkleBlockHandler
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
