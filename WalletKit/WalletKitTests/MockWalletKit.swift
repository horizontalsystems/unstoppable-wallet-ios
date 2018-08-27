import Foundation
import Cuckoo
import RealmSwift
@testable import WalletKit

class MockWalletKit {

    let mockNetwork: MockNetworkProtocol
    let mockRealmFactory: MockRealmFactory
    let mockLogger: MockLogger

    let mockHdWallet: MockHDWallet

    let mockStateManager: MockStateManager
    let mockApiManager: MockApiManager

    let mockPeerGroup: MockPeerGroup
    let mockSyncer: MockSyncer
    let mockFactory: MockFactory

    let mockInitialSyncer: MockInitialSyncer

    let mockDifficultyEncoder: MockDifficultyEncoder
    let mockDifficultyCalculator: MockDifficultyCalculator

    let mockBlockValidator: MockBlockValidator

    let mockBlockSyncer: MockBlockSyncer
    let mockMerkleBlockValidator: MockMerkleBlockValidator

    let mockHeaderSyncer: MockHeaderSyncer
    let mockHeaderHandler: MockHeaderHandler

    let mockAddressConverter: MockAddressConverter
    let mockScriptConverter: MockScriptConverter
    let mockTransactionProcessor: MockTransactionProcessor
    let mockTransactionExtractor: MockTransactionExtractor
    let mockTransactionLinker: MockTransactionLinker
    let mockTransactionHandler: MockTransactionHandler
    let mockTransactionSender: MockTransactionSender
    let mockTransactionCreator: MockTransactionCreator
    let mockTransactionBuilder: MockTransactionBuilder

    let mockInputSigner: MockInputSigner
    let mockScriptBuilder: MockScriptBuilder
    let mockTransactionSizeCalculator: MockTransactionSizeCalculator
    let mockUnspentOutputSelector: MockUnspentOutputSelector
    let mockUnspentOutputProvider: MockUnspentOutputProvider

    let mockRealm: Realm

    public init() {
        mockNetwork = MockNetworkProtocol()

        stub(mockNetwork) { mock in
            when(mock.coinType.get).thenReturn(1)
            when(mock.dnsSeeds.get).thenReturn([""])
            when(mock.port.get).thenReturn(0)
        }

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        mockLogger = MockLogger()

        mockHdWallet = MockHDWallet(seed: Data(), network: mockNetwork)

        mockStateManager = MockStateManager(realmFactory: mockRealmFactory)
        mockApiManager = MockApiManager(apiUrl: "")

        mockPeerGroup = MockPeerGroup(realmFactory: mockRealmFactory, network: mockNetwork)
        mockSyncer = MockSyncer(logger: mockLogger, realmFactory: mockRealmFactory)
        mockFactory = MockFactory()

        mockInitialSyncer = MockInitialSyncer(realmFactory: mockRealmFactory, hdWallet: mockHdWallet, stateManager: mockStateManager, apiManager: mockApiManager, peerGroup: mockPeerGroup)

        mockDifficultyEncoder = MockDifficultyEncoder()
        mockDifficultyCalculator = MockDifficultyCalculator(difficultyEncoder: mockDifficultyEncoder)

        mockBlockValidator = MockBlockValidator(calculator: mockDifficultyCalculator)

        mockBlockSyncer = MockBlockSyncer(realmFactory: mockRealmFactory, peerGroup: mockPeerGroup)
        mockMerkleBlockValidator = MockMerkleBlockValidator()

        mockHeaderSyncer = MockHeaderSyncer(realmFactory: mockRealmFactory, peerGroup: mockPeerGroup, network: mockNetwork)
        mockHeaderHandler = MockHeaderHandler(realmFactory: mockRealmFactory, factory: mockFactory, validator: mockBlockValidator, blockSyncer: mockBlockSyncer, network: mockNetwork)

        mockInputSigner = MockInputSigner(hdWallet: mockHdWallet)
        mockScriptBuilder = MockScriptBuilder()

        mockTransactionSizeCalculator = MockTransactionSizeCalculator()
        mockUnspentOutputSelector = MockUnspentOutputSelector(calculator: mockTransactionSizeCalculator)
        mockUnspentOutputProvider = MockUnspentOutputProvider(realmFactory: mockRealmFactory)

        mockAddressConverter = MockAddressConverter(network: mockNetwork)
        mockScriptConverter = MockScriptConverter()
        mockTransactionExtractor = MockTransactionExtractor(scriptConverter: mockScriptConverter, addressConverter: mockAddressConverter)
        mockTransactionLinker = MockTransactionLinker()
        mockTransactionProcessor = MockTransactionProcessor(realmFactory: mockRealmFactory, extractor: mockTransactionExtractor, linker: mockTransactionLinker, logger: mockLogger)
        mockTransactionHandler = MockTransactionHandler(realmFactory: mockRealmFactory, processor: mockTransactionProcessor, headerHandler: mockHeaderHandler, factory: mockFactory)
        mockTransactionSender = MockTransactionSender(realmFactory: mockRealmFactory, peerGroup: mockPeerGroup)
        mockTransactionBuilder = MockTransactionBuilder(unspentOutputSelector: mockUnspentOutputSelector, unspentOutputProvider: mockUnspentOutputProvider, transactionSizeCalculator: mockTransactionSizeCalculator, addressConverter: mockAddressConverter, inputSigner: mockInputSigner, scriptBuilder: mockScriptBuilder, factory: mockFactory)
        mockTransactionCreator = MockTransactionCreator(realmFactory: mockRealmFactory, transactionBuilder: mockTransactionBuilder, transactionSender: mockTransactionSender)

//        mockPeerGroup.delegate = mockSyncer
//
//        mockSyncer.headerSyncer = mockHeaderSyncer
//        mockSyncer.headerHandler = mockHeaderHandler
//        mockSyncer.transactionHandler = mockTransactionHandler
//        mockSyncer.blockSyncer = mockBlockSyncer

        mockRealm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! mockRealm.write { mockRealm.deleteAll() }

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(mockRealm)
        }
    }

}
