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
    private var mockTransactionHandler: MockTransactionHandler!
    private var syncer: Syncer!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        DefaultValueRegistry.register(value: TestNet(), forType: NetworkProtocol.self)

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        mockLogger = MockLogger()
        mockHeaderSyncer = MockHeaderSyncer(realmFactory: mockRealmFactory, peerGroup: PeerGroupStub(realmFactory: mockRealmFactory), configuration: ConfigurationStub())
        mockHeaderHandler = MockHeaderHandler(realmFactory: mockRealmFactory, factory: FactoryStub(), validator: BlockValidatorStub(calculator: DifficultyCalculatorStub(difficultyEncoder: DifficultyEncoderStub())), blockSyncer: BlockSyncerStub(realmFactory: mockRealmFactory, peerGroup: PeerGroupStub(realmFactory: mockRealmFactory)), configuration: ConfigurationStub())
        mockTransactionHandler = MockTransactionHandler(realmFactory: mockRealmFactory, processor: TransactionProcessorStub(realmFactory: mockRealmFactory, extractor: TransactionExtractorStub(addressConverter: AddressConverterStub(network: TestNet())), linker: TransactionLinkerStub(), logger: LoggerStub()))

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
        stub(mockTransactionHandler) { mock in
            when(mock.handle(blockTransactions: any(), blockHeaderHash: any())).thenDoNothing()
            when(mock.handle(memPoolTransactions: any())).thenDoNothing()
        }

        syncer = Syncer(logger: mockLogger, realmFactory: mockRealmFactory)
        syncer.headerSyncer = mockHeaderSyncer
        syncer.headerHandler = mockHeaderHandler
        syncer.transactionHandler = mockTransactionHandler
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockLogger = nil
        mockHeaderSyncer = nil
        mockHeaderHandler = nil
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

        syncer.peerGroupDidReceive(headers: headers)

        verify(mockHeaderHandler).handle(headers: equal(to: headers))
    }

    func testRunHeaderHandler_Error() {
        let error = TestError()

        stub(mockHeaderHandler) { mock in
            when(mock.handle(headers: any())).thenThrow(error)
        }

        let headers: [BlockHeader] = [TestData.firstBlock.header, TestData.secondBlock.header]

        syncer.peerGroupDidReceive(headers: headers)

        verify(mockLogger).log(tag: "Header Handler Error", message: "\(error)")
    }

    func testRunTransactions() {
        let blockHeaderHash = TestData.checkpointBlock.reversedHeaderHashHex.reversedData!
        let transaction = TestData.p2pkhTransaction

        syncer.peerGroupDidReceive(blockHeaderHash: blockHeaderHash, withTransactions: [transaction])
        verify(mockTransactionHandler).handle(blockTransactions: equal(to: [transaction]), blockHeaderHash: equal(to: blockHeaderHash))
    }

    func testRunTransactions_Error() {
        let error = TestError()
        stub(mockTransactionHandler) { mock in
            when(mock.handle(blockTransactions: any(), blockHeaderHash: any())).thenThrow(error)
        }

        let blockHeaderHash = TestData.checkpointBlock.reversedHeaderHashHex.reversedData!
        let transaction = TestData.p2pkhTransaction

        syncer.peerGroupDidReceive(blockHeaderHash: blockHeaderHash, withTransactions: [transaction])
        verify(mockLogger).log(tag: "Transaction Handler Error", message: "\(error)")
    }

    func testRunTransactionHandler() {
        let transaction = TestData.p2pkhTransaction
        syncer.peerGroupDidReceive(transaction: transaction)

        verify(mockTransactionHandler).handle(memPoolTransactions: equal(to: [transaction]))
    }

    func testRunTransactionHandler_Error() {
        let error = TestError()

        stub(mockTransactionHandler) { mock in
            when(mock.handle(memPoolTransactions: any())).thenThrow(error)
        }

        let transaction = TestData.p2pkhTransaction
        syncer.peerGroupDidReceive(transaction: transaction)

        verify(mockLogger).log(tag: "Transaction Handler Error", message: "\(error)")
    }

}
