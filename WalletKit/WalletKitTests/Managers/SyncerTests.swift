import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class SyncerTests: XCTestCase {

    class TestError: Error, CustomStringConvertible {
        private(set) var description: String = "test error"
    }

    private var mockRealmFactory: MockRealmFactory!
    private var mockLogger: MockLogger!
    private var mockHeaderSyncer: MockHeaderSyncer!
    private var mockHeaderHandler: MockHeaderHandler!
    private var mockMerkleBlockHandler: MockMerkleBlockHandler!
    private var mockTransactionHandler: MockTransactionHandler!
    private var syncer: Syncer!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        DefaultValueRegistry.register(value: TestNet(), forType: NetworkProtocol.self)

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        mockLogger = MockLogger()
        mockHeaderSyncer = MockHeaderSyncer(realmFactory: mockRealmFactory, peerGroup: PeerGroupStub(realmFactory: mockRealmFactory), configuration: ConfigurationStub())
        mockHeaderHandler = MockHeaderHandler(realmFactory: mockRealmFactory, factory: FactoryStub(), validator: BlockValidatorStub(calculator: DifficultyCalculatorStub(difficultyEncoder: DifficultyEncoderStub())), saver: BlockSaverStub(realmFactory: mockRealmFactory), configuration: ConfigurationStub())
        mockMerkleBlockHandler = MockMerkleBlockHandler(realmFactory: mockRealmFactory, validator: MerkleBlockValidatorStub(), saver: BlockSaverStub(realmFactory: mockRealmFactory))
        mockTransactionHandler = MockTransactionHandler(realmFactory: mockRealmFactory, extractor: TransactionExtractorStub(addressConverter: AddressConverter(network: TestNet())), saver: TransactionSaverStub(realmFactory: mockRealmFactory), linker: TransactionLinkerStub(realmFactory: mockRealmFactory))

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockLogger) { mock in
            when(mock.log(tag: any(), message: any())).thenDoNothing()
        }
        stub(mockHeaderSyncer) { mock in
            when(mock.sync()).thenDoNothing()
        }
        stub(mockHeaderHandler) { mock in
            when(mock.handle(headers: any())).thenDoNothing()
        }
        stub(mockMerkleBlockHandler) { mock in
            when(mock.handle(message: any())).thenDoNothing()
        }
        stub(mockTransactionHandler) { mock in
            when(mock.handle(transaction: any())).thenDoNothing()
        }

        syncer = Syncer(logger: mockLogger, realmFactory: mockRealmFactory)
        syncer.headerSyncer = mockHeaderSyncer
        syncer.headerHandler = mockHeaderHandler
        syncer.merkleBlockHandler = mockMerkleBlockHandler
        syncer.transactionHandler = mockTransactionHandler
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockLogger = nil
        mockHeaderSyncer = nil
        mockHeaderHandler = nil
        mockMerkleBlockHandler = nil
        mockTransactionHandler = nil
        syncer = nil

        realm = nil

        super.tearDown()
    }

    func testRunHeaderSyncerOnConnect() {
        syncer.peerGroupDidConnect()
        verify(mockHeaderSyncer).sync()
    }

    func testRunHeaderSyncerOnConnect_Error() {
        let error = TestError()

        stub(mockHeaderSyncer) { mock in
            when(mock.sync()).thenThrow(error)
        }

        syncer.peerGroupDidConnect()
        verify(mockLogger).log(tag: "Header Syncer Error", message: "\(error)")
    }

    func testRunHeaderHandler() {
        let headers: [BlockHeader] = [TestData.firstBlock.header, TestData.secondBlock.header]

//        syncer.peerGroupDidReceive(headers: headers)
//
//        verify(mockHeaderHandler).handle(headers: equal(to: headers))
    }

    func testRunHeaderHandler_Error() {
        let error = TestError()

        stub(mockHeaderHandler) { mock in
            when(mock.handle(headers: any())).thenThrow(error)
        }

        let headers: [BlockHeader] = [TestData.firstBlock.header, TestData.secondBlock.header]

//        syncer.peerGroupDidReceive(headers: headers)
//
//        verify(mockLogger).log(tag: "Header Handler Error", message: "\(error)")
    }

    func testRunMerkleBlockHandler() {
        let message = MerkleBlockMessage(blockHeader: BlockHeader(), totalTransactions: 0, numberOfHashes: 0, hashes: [], numberOfFlags: 0, flags: [])
//        syncer.peerGroupDidReceive(merkleBlock: message)
//
//        verify(mockMerkleBlockHandler).handle(message: equal(to: message))
    }

    func testRunMerkleBlockHandler_Error() {
        let error = TestError()

        stub(mockMerkleBlockHandler) { mock in
            when(mock.handle(message: any())).thenThrow(error)
        }

        let message = MerkleBlockMessage(blockHeader: BlockHeader(), totalTransactions: 0, numberOfHashes: 0, hashes: [], numberOfFlags: 0, flags: [])
//        syncer.peerGroupDidReceive(merkleBlock: message)
//
//        verify(mockLogger).log(tag: "Merkle Block Handler Error", message: "\(error)")
    }

    func testRunTransactionHandler() {
        let transaction = TestData.p2pkhTransaction
//        syncer.peerGroupDidReceive(transaction: transaction)
//
//        verify(mockTransactionHandler).handle(transaction: equal(to: transaction))
    }

    func testRunTransactionHandler_Error() {
        let error = TestError()

        stub(mockTransactionHandler) { mock in
            when(mock.handle(transaction: any())).thenThrow(error)
        }

        let transaction = TestData.p2pkhTransaction
//        syncer.peerGroupDidReceive(transaction: transaction)
//
//        verify(mockLogger).log(tag: "Transaction Handler Error", message: "\(error)")
    }

}
