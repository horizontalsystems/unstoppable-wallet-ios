import Foundation
import RealmSwift
import RxSwift

public class WalletKit {

    public enum NetworkType {
        case mainNet
        case testNet
        case regTest
    }

    let disposeBag = DisposeBag()

    let network: NetworkProtocol
    let realmFactory: RealmFactory
    let logger: Logger

    let hdWallet: HDWallet

    let stateManager: StateManager
    let apiManager: ApiManager
    let addressManager: AddressManager

    let peerGroup: PeerGroup
    let syncer: Syncer
    let factory: Factory

    let initialSyncer: InitialSyncer

    let difficultyEncoder: DifficultyEncoder
    let difficultyCalculator: DifficultyCalculator

    let blockValidator: BlockValidator

    let blockSyncer: BlockSyncer
    let merkleBlockValidator: MerkleBlockValidator

    let headerSyncer: HeaderSyncer
    let headerHandler: HeaderHandler

    let addressConverter: AddressConverter
    let scriptConverter: ScriptConverter
    let transactionProcessor: TransactionProcessor
    let transactionExtractor: TransactionExtractor
    let transactionLinker: TransactionLinker
    let transactionHandler: TransactionHandler
    let transactionSender: TransactionSender
    let transactionCreator: TransactionCreator
    let transactionBuilder: TransactionBuilder

    let inputSigner: InputSigner
    let scriptBuilder: ScriptBuilder
    let transactionSizeCalculator: TransactionSizeCalculator
    let unspentOutputSelector: UnspentOutputSelector
    let unspentOutputProvider: UnspentOutputProvider

    public init(withWords words: [String], realmConfiguration: Realm.Configuration, networkType: NetworkType = .mainNet) {
        switch networkType {
        case .mainNet: self.network = MainNet()
        case .testNet: self.network = TestNet()
        case .regTest: self.network = RegTest()
        }

        realmFactory = RealmFactory(configuration: realmConfiguration)
        logger = Logger()

        hdWallet = HDWallet(seed: Mnemonic.seed(mnemonic: words), network: network)

        stateManager = StateManager(realmFactory: realmFactory)
        apiManager = ApiManager(apiUrl: "http://blocknode.grouvi.org/api/v1/blockchain/btc")

        peerGroup = PeerGroup(realmFactory: realmFactory, network: network)
        syncer = Syncer(logger: logger, realmFactory: realmFactory)
        factory = Factory()

        initialSyncer = InitialSyncer(realmFactory: realmFactory, hdWallet: hdWallet, stateManager: stateManager, apiManager: apiManager, peerGroup: peerGroup)
        addressManager = AddressManager(realmFactory: realmFactory, hdWallet: hdWallet)

        difficultyEncoder = DifficultyEncoder()
        difficultyCalculator = DifficultyCalculator(difficultyEncoder: difficultyEncoder)

        blockValidator = networkType == .mainNet ? BlockValidator(calculator: difficultyCalculator) : TestNetBlockValidator(calculator: difficultyCalculator)

        blockSyncer = BlockSyncer(realmFactory: realmFactory, peerGroup: peerGroup)
        merkleBlockValidator = MerkleBlockValidator()

        headerSyncer = HeaderSyncer(realmFactory: realmFactory, peerGroup: peerGroup, network: network)
        headerHandler = HeaderHandler(realmFactory: realmFactory, factory: factory, validator: blockValidator, blockSyncer: blockSyncer, network: network)

        inputSigner = InputSigner(hdWallet: hdWallet)
        scriptBuilder = ScriptBuilder()

        transactionSizeCalculator = TransactionSizeCalculator()
        unspentOutputSelector = UnspentOutputSelector(calculator: transactionSizeCalculator)
        unspentOutputProvider = UnspentOutputProvider(realmFactory: realmFactory)

        addressConverter = AddressConverter(network: network)
        scriptConverter = ScriptConverter()
        transactionExtractor = TransactionExtractor(scriptConverter: scriptConverter, addressConverter: addressConverter)
        transactionLinker = TransactionLinker()
        transactionProcessor = TransactionProcessor(realmFactory: realmFactory, extractor: transactionExtractor, linker: transactionLinker, addressManager: addressManager, logger: logger)
        transactionHandler = TransactionHandler(realmFactory: realmFactory, processor: transactionProcessor, headerHandler: headerHandler, factory: factory)
        transactionSender = TransactionSender(realmFactory: realmFactory, peerGroup: peerGroup)
        transactionBuilder = TransactionBuilder(unspentOutputSelector: unspentOutputSelector, unspentOutputProvider: unspentOutputProvider, transactionSizeCalculator: transactionSizeCalculator, addressConverter: addressConverter, inputSigner: inputSigner, scriptBuilder: scriptBuilder, factory: factory)
        transactionCreator = TransactionCreator(realmFactory: realmFactory, transactionBuilder: transactionBuilder, transactionSender: transactionSender, addressManager: addressManager)

        peerGroup.delegate = syncer

        syncer.headerSyncer = headerSyncer
        syncer.headerHandler = headerHandler
        syncer.transactionHandler = transactionHandler
        syncer.blockSyncer = blockSyncer
    }

    public func showRealmInfo() {
        let realm = realmFactory.realm

        let blockCount = realm.objects(Block.self).count
        let syncedBlockCount = realm.objects(Block.self).filter("synced = %@", true).count
        let pubKeysCount = realm.objects(PublicKey.self).count

        print("BLOCK COUNT: \(blockCount) --- \(syncedBlockCount) synced")
        if let block = realm.objects(Block.self).first {
            print("First Block: \(block.height) --- \(block.reversedHeaderHashHex)")
        }
        if let block = realm.objects(Block.self).last {
            print("Last Block: \(block.height) --- \(block.reversedHeaderHashHex)")
        }

        print("PUBLIC KEYS COUNT: \(pubKeysCount)")
        for pubKey in realm.objects(PublicKey.self) {
            print("\(pubKey.index) --- \(pubKey.external) --- \(pubKey.address)")
        }
    }

    public func start() throws {
        try initialSyncer.sync()
    }

    public func clear() throws {
        let realm = realmFactory.realm

        try realm.write {
            realm.deleteAll()
        }
    }

    public var transactionsRealmResults: Results<Transaction> {
        return realmFactory.realm.objects(Transaction.self).filter("isMine = %@", true).sorted(byKeyPath: "block.height", ascending: false)
    }

    public var latestBlockHeight: Int {
        return realmFactory.realm.objects(Block.self).sorted(byKeyPath: "height").last?.height ?? 0
    }

    public var unspentOutputsRealmResults: Results<TransactionOutput> {
        return realmFactory.realm.objects(TransactionOutput.self)
                .filter("publicKey != nil")
                .filter("scriptType = %@ OR scriptType = %@", ScriptType.p2pkh.rawValue, ScriptType.p2pk.rawValue)
                .filter("inputs.@count = %@", 0)
    }

    public func send(to address: String, value: Int) throws {
        try transactionCreator.create(to: address, value: value)
    }

    public func fee(for value: Int, senderPay: Bool) throws -> Int {
        return try transactionBuilder.fee(for: value, feeRate: transactionCreator.feeRate, senderPay: true, type: .p2pkh)
    }

    public var receiveAddress: String {
        return (try? addressManager.receiveAddress()) ?? ""
    }

}
