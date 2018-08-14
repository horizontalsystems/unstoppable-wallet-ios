import XCTest
import Cuckoo
import RealmSwift
import RxSwift
@testable import WalletKit

class TransactionSenderTests: XCTestCase {

    private var mockRealmFactory: MockRealmFactory!
    private var mockPeerGroup: MockPeerGroup!
    private var transactionSender: TransactionSender!

    private var realm: Realm!
    private var peerStatusSubject: PublishSubject<PeerGroup.Status>!

    override func setUp() {
        super.setUp()

        mockRealmFactory = MockRealmFactory(configuration: Realm.Configuration())
        mockPeerGroup = MockPeerGroup(realmFactory: mockRealmFactory)

        realm = try! Realm(configuration: Realm.Configuration(inMemoryIdentifier: "TestRealm"))
        try! realm.write { realm.deleteAll() }

        peerStatusSubject = PublishSubject()

        stub(mockRealmFactory) { mock in
            when(mock.realm.get).thenReturn(realm)
        }
        stub(mockPeerGroup) { mock in
            when(mock.relay(transaction: any())).thenDoNothing()
            when(mock.statusSubject.get).thenReturn(peerStatusSubject)
        }

        transactionSender = TransactionSender(realmFactory: mockRealmFactory, peerGroup: mockPeerGroup, scheduler: MainScheduler.instance, queue: .main)
    }

    override func tearDown() {
        transactionSender = nil
        mockPeerGroup = nil
        mockRealmFactory = nil

        realm = nil
        peerStatusSubject = nil

        super.tearDown()
    }

    func testSyncConnectedAvoidResend() {
        peerStatusSubject.onNext(.connected)
        verify(mockPeerGroup, never()).relay(transaction: any())
    }

    func testSyncAddedNotNewTransactionAvoidResend() {
        let e = expectation(description: "Realm Observer")

        let token = realm.objects(Transaction.self).filter("status = %@", TransactionStatus.relayed.rawValue).observe { changes in
            if case let .update(_, _, insertions, _) = changes, !insertions.isEmpty {
                e.fulfill()
            }
        }
        let transaction = TestData.p2pkhTransaction
        transaction.status = .relayed
        try? realm.write {
            realm.add(transaction, update: true)
        }

        waitForExpectations(timeout: 2)
        verify(mockPeerGroup, never()).relay(transaction: any())

        token.invalidate()
    }

    func testSyncAddedNewTransactionResend() {
        let e = expectation(description: "Realm Observer")

        let token = realm.objects(Transaction.self).filter("status = %@", TransactionStatus.new.rawValue).observe { changes in
            if case let .update(_, _, insertions, _) = changes, !insertions.isEmpty {
                e.fulfill()
            }
        }
        let transaction = TestData.p2pkhTransaction
        transaction.status = .new
        let transaction2 = TestData.p2pkTransaction
        transaction2.status = .relayed
        try? realm.write {
            realm.add(transaction, update: true)
            realm.add(transaction2, update: true)
        }

        waitForExpectations(timeout: 2)
        verify(mockPeerGroup, times(1)).relay(transaction: equal(to: transaction))
        verify(mockPeerGroup, never()).relay(transaction: equal(to: transaction2))

        token.invalidate()
    }

    func testConnectedTransactionResend() {
        let transaction = TestData.p2pkhTransaction
        transaction.status = .new
        try? realm.write {
            realm.add(transaction, update: true)
        }
        peerStatusSubject.onNext(.connected)
        verify(mockPeerGroup, times(1)).relay(transaction: any())
    }

}
