import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionCreatorTests: XCTestCase {

    private var realm: Realm!
    private var mockTransactionBuilder: MockTransactionBuilder!

    private var transactionCreator: TransactionCreator!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        realm = mockWalletKit.mockRealm

        try! realm.write {
            realm.add(TestData.pubKey())
        }

        mockTransactionBuilder = mockWalletKit.mockTransactionBuilder

        stub(mockTransactionBuilder) { mock in
            when(mock.buildTransaction(value: any(), feeRate: any(), type: any(), changePubKey: any(), toAddress: any())).thenReturn(TestData.p2pkhTransaction)
        }

        transactionCreator = TransactionCreator(realmFactory: mockWalletKit.mockRealmFactory, transactionBuilder: mockTransactionBuilder)
    }

    override func tearDown() {
        realm = nil
        mockTransactionBuilder = nil
        transactionCreator = nil

        super.tearDown()
    }

    func testCreateTransaction() {
        try! transactionCreator.create(to: "Address", value: 1)

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
            try transactionCreator.create(to: "Address", value: 1)
            XCTFail("No exception!")
        } catch let error as TransactionCreator.CreationError {
            XCTAssertEqual(error, TransactionCreator.CreationError.noChangeAddress)
        } catch {
            XCTFail("Unexpected exception!")
        }
    }

}
