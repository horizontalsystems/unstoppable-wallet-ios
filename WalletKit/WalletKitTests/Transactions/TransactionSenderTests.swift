import XCTest
import Cuckoo
import RealmSwift
import RxSwift
@testable import WalletKit

class TransactionSenderTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockPeerGroup: MockPeerGroup!
    private var sender: TransactionSender!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        mockPeerGroup = mockWalletKit.mockPeerGroup
        realm = mockWalletKit.realm

        stub(mockPeerGroup) { mock in
            when(mock.relay(transaction: any())).thenDoNothing()
        }

        sender = TransactionSender(realmFactory: mockWalletKit.mockRealmFactory, peerGroup: mockPeerGroup, queue: .main)
    }

    override func tearDown() {
        mockPeerGroup = nil
        sender = nil

        realm = nil

        super.tearDown()
    }

    func testNoNewTransactions() {
        sender.enqueueRun()
        waitForMainQueue()

        verify(mockPeerGroup, never()).relay(transaction: any())
    }

    func testNewTransactions() {
        let transaction = TestData.p2pkhTransaction
        transaction.status = .new

        try! realm.write {
            realm.add(transaction)
        }

        sender.enqueueRun()
        waitForMainQueue()

        verify(mockPeerGroup).relay(transaction: equal(to: transaction))
    }

    func testNewAndRelayedTransactions() {
        let newTransaction = TestData.p2pkhTransaction
        newTransaction.status = .new

        let relayedTransaction = TestData.p2pkTransaction
        relayedTransaction.status = .relayed

        try! realm.write {
            realm.add(newTransaction)
            realm.add(relayedTransaction)
        }

        sender.enqueueRun()
        waitForMainQueue()

        verify(mockPeerGroup).relay(transaction: equal(to: newTransaction))
        verify(mockPeerGroup, never()).relay(transaction: equal(to: relayedTransaction))
    }

}
