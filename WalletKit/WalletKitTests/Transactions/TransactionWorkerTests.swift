import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionWorkerTests: XCTestCase{
    private var mockRealmFactory: MockRealmFactory!
    private var mockProcessor: MockTransactionProcessor!
    private var worker: TransactionWorker!

    private var realm: Realm!
    private var transaction: Transaction!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write {
            realm.deleteAll()
        }
        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }

        let mockExtractor = MockTransactionExtractor(addressConverter: AddressConverter(network: TestNet()))
        let mockLinker = MockTransactionLinker()
        let mockLogger = MockLogger()
        mockProcessor = MockTransactionProcessor(extractor: mockExtractor, linker: mockLinker, logger: mockLogger)
        worker = TransactionWorker(realmFactory: mockRealmFactory, processor: mockProcessor, sync: true)

        stub(mockProcessor) { mock in
            when(mock.process(realm: any(), transactions: any())).thenDoNothing()
        }
        transaction = TestData.p2pkhTransaction
    }

    override func tearDown() {
        mockRealmFactory = nil
        mockProcessor = nil
        worker = nil

        realm = nil
        transaction = nil

        super.tearDown()
    }

    func testProcessorTriggered() {
        let e = expectation(description: "Realm Observer")

        let token = realm.objects(Transaction.self).filter("processed = %@", false).observe { changes in
            if case let .update(_, _, insertions, _) = changes, !insertions.isEmpty {
                e.fulfill()
            }
        }

        let transaction2 = TestData.p2pkTransaction
        transaction2.processed = true
        transaction.processed = false
        try? realm.write {
            realm.add([transaction, transaction2], update: true)
        }

        waitForExpectations(timeout: 2)
        let argumentCaptor = ArgumentCaptor<Results<Transaction>>()
        verify(mockProcessor, times(1)).process(realm: equal(to: realm), transactions: argumentCaptor.capture())
        XCTAssertEqual(argumentCaptor.value?.count, 1)
        XCTAssertEqual(argumentCaptor.value?[0].reversedHashHex, transaction.reversedHashHex)

        token.invalidate()
    }

}
