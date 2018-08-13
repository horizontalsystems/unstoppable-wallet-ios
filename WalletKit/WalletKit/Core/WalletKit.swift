import Foundation
import RealmSwift

public class WalletKit {
    let configuration: Configuration
    let realmFactory: RealmFactory

    let hdWallet: HDWallet

    public let walletKitProvider: WalletKitProvider

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
    let unspentOutputsManager: UnspentOutputManager

    public init(withWords words: [String], realmConfiguration: Realm.Configuration) {
        configuration = Configuration()
        realmFactory = RealmFactory(configuration: realmConfiguration)

        hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), network: configuration.network)

        walletKitProvider = WalletKitProvider(realmFactory: realmFactory)

        peerGroup = PeerGroup(realmFactory: realmFactory)
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

        inputSigner = InputSigner(realmFactory: realmFactory, hdWallet: hdWallet)
        scriptBuilder = ScriptBuilder()
        unspentOutputsManager = UnspentOutputManager(realmFactory: realmFactory)

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
        let addressCount = realm.objects(Address.self).count

        print("BLOCK COUNT: \(blockCount)")
        if let block = realm.objects(Block.self).first {
            print("First Block: \(block.height) --- \(block.reversedHeaderHashHex)")
        }
        if let block = realm.objects(Block.self).last {
            print("Last Block: \(block.height) --- \(block.reversedHeaderHashHex)")
        }

        print("ADDRESS COUNT: \(addressCount)")
        if let address = realm.objects(Address.self).first {
            print("First Address: \(address.index) --- \(address.external) --- \(address.base58)")
        }
        if let address = realm.objects(Address.self).last {
            print("Last Address: \(address.index) --- \(address.external) --- \(address.base58)")
        }
    }

    public func start() throws {
        peerGroup.connect()
    }

    private func preFillInitialTestData() {
        let realm = realmFactory.realm

        var addresses = [Address]()

        for i in 0..<10 {
            if let address = try? hdWallet.receiveAddress(index: i) {
                addresses.append(address)
            }
            if let address = try? hdWallet.changeAddress(index: i) {
                addresses.append(address)
            }
        }

        try? realm.write {
            realm.add(addresses, update: true)
        }
    }

}
