import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class HDPrivateKeyTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCorrectDerivedKey() {
        let privateKey = HDPrivateKey(privateKey: Data(hex: "6a787b30bd81c8fa5ed09175b5fb08e179cf429ba91ca649dd3317436b7b698e")!, chainCode: Data(), network: MockWalletKit().mockNetwork)

        XCTAssertEqual(privateKey.raw.hex, "6a787b30bd81c8fa5ed09175b5fb08e179cf429ba91ca649dd3317436b7b698e")
    }

    func testCorrectDerivedKey_SmallLength() {
        let privateKey = HDPrivateKey(privateKey: Data(hex: "4c16165875d0bed9a76e4ba83fae65c80076f60791d956f336a2d7a3b21185")!, chainCode: Data(), network: MockWalletKit().mockNetwork)

        XCTAssertEqual(privateKey.raw.hex, "004c16165875d0bed9a76e4ba83fae65c80076f60791d956f336a2d7a3b21185")
    }

}
