import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class SyncerTests: XCTestCase {

    private var manager: Syncer!

    override func setUp() {
        super.setUp()

        manager = Syncer()
    }

    override func tearDown() {
        manager = nil

        super.tearDown()
    }

    func testOne() {
    }

}
