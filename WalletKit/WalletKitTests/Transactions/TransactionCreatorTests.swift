import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionCreatorTests: XCTestCase {

    private var realm: Realm!
    private var mockRealmFactory: MockRealmFactory!
    private var mockTransactionBuilder: MockTransactionBuilder!

    private var transactionCreator: TransactionCreator!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write {
            realm.deleteAll()
            realm.add(TestData.pubKey())
        }
        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }

        mockTransactionBuilder = MockTransactionBuilder(unspentOutputSelector: UnspentOutputSelectorStub(), unspentOutputProvider: UnspentOutputProviderStub(realmFactory: mockRealmFactory), addressConverter: AddressConverterStub(network: TestNet()), inputSigner: InputSignerStub(hdWallet: HDWallet(seed: Data(), network: TestNet())), scriptBuilder: ScriptBuilderStub(), factory: FactoryStub())
        stub(mockTransactionBuilder) { mock in
            when(mock.buildTransaction(value: any(), feeRate: any(), type: any(), changePubKey: any(), toAddress: any())).thenReturn(TestData.p2pkhTransaction)
        }

        transactionCreator = TransactionCreator(realmFactory: mockRealmFactory, transactionBuilder: mockTransactionBuilder)
    }

    override func tearDown() {
        mockRealmFactory = nil
        realm = nil
        mockTransactionBuilder = nil
        transactionCreator = nil

        super.tearDown()
    }

    func testCreateTransaction() {
        try! transactionCreator.create(to: "Fuck you!", value: 1)

        guard let _ = realm.objects(Transaction.self).filter("reversedHashHex = %@", TestData.p2pkhTransaction.reversedHashHex).first else {
            XCTFail("No transaction record!")
            return
        }
    }

    func testNoChangeAddress() {
        try! realm.write {
            realm.deleteAll()
        }
        do {
            try transactionCreator.create(to: "Fuck you!", value: 1)
            XCTFail("No exception!")
        } catch let error as TransactionCreator.CreationError {
            XCTAssertEqual(error, TransactionCreator.CreationError.noChangeAddress)
        } catch {
            XCTFail("Unexpected exception!")
        }
    }

}
