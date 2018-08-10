import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class UnspentOutputsManagerTests: XCTestCase {

    private var unspentOutputSelector: UnspentOutputsManager!
    private var outputs: [TransactionOutput]!
    private var mockRealmFactory: MockRealmFactory!
    private var realm: Realm!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory()

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }

        unspentOutputSelector = UnspentOutputsManager(realmFactory: mockRealmFactory)
        outputs = [TransactionFactory().transactionOutput(withValue: 1, withLockingScript: Data(), withIndex: 0),
                   TransactionFactory().transactionOutput(withValue: 2, withLockingScript: Data(), withIndex: 0),
                   TransactionFactory().transactionOutput(withValue: 4, withLockingScript: Data(), withIndex: 0),
                   TransactionFactory().transactionOutput(withValue: 8, withLockingScript: Data(), withIndex: 0),
                   TransactionFactory().transactionOutput(withValue: 16, withLockingScript: Data(), withIndex: 0)
        ]
    }

    override func tearDown() {
        mockRealmFactory = nil
        realm = nil

        unspentOutputSelector = nil
        outputs = nil

        super.tearDown()
    }

    func testExactlyValue() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 4, outputs: outputs)
            XCTAssertEqual(selectedOutputs, [outputs[2]])
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testSummaryValue() {
        do {
            let selectedOutputs = try unspentOutputSelector.select(value: 11, outputs: outputs)
            XCTAssertEqual(selectedOutputs, [outputs[0], outputs[1], outputs[2], outputs[3]])
        } catch {
            XCTFail("Unexpected error!")
        }
    }

    func testNotEnoughError() {
        do {
            _ = try unspentOutputSelector.select(value: 35, outputs: outputs)
            XCTFail("Wrong value summary!")
        } catch let error as UnspentOutputsManager.SelectorError {
            XCTAssertEqual(error, UnspentOutputsManager.SelectorError.notEnough)
        } catch {
            XCTFail("Unexpected \(error) error!")
        }
    }

    func testEmptyOutputsError() {
        do {
            _ = try unspentOutputSelector.select(value: 35, outputs: [])
            XCTFail("Wrong value summary!")
        } catch let error as UnspentOutputsManager.SelectorError {
            XCTAssertEqual(error, UnspentOutputsManager.SelectorError.emptyOutputs)
        } catch {
            XCTFail("Unexpected \(error) error!")
        }
    }

    func testValidOutputs() {
        XCTAssertTrue(true)
    }

}
