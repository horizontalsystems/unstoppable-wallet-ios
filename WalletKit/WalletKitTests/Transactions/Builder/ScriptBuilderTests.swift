import XCTest
import Cuckoo
@testable import WalletKit

class ScriptBuilderTests: XCTestCase {

    private var builder: ScriptBuilder!

    override func setUp() {
        super.setUp()

        builder = ScriptBuilder()
    }

    override func tearDown() {
        builder = nil

        super.tearDown()
    }

    func testP2PKH() {
        let data = Data(hex: "76a914cbc20a7664f2f69e5355aa427045bc15e7c6c77288ac")!
        let pubKey = Data(hex: "cbc20a7664f2f69e5355aa427045bc15e7c6c772")!

        do {
            let test = try builder.lockingScript(type: .p2pkh, params: [pubKey])
            XCTAssertEqual(test, data)
        } catch {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testP2PKHDataError() {
        do {
            _ = try builder.lockingScript(type: .p2pkh, params: [Data(), Data()])
            XCTFail("No Exception Thrown")
        } catch let error as ScriptBuilder.BuildError {
            XCTAssertEqual(error, ScriptBuilder.BuildError.wrongDataCount)
        } catch {
            XCTFail("\(error) Exception Thrown")
        }

    }

    func testP2PK() {
        let data = Data(hex: "21030e7061b9fb18571cf2441b2a7ee2419933ddaa423bc178672cd11e87911616d1ac")!
        let pubKey = Data(hex: "030e7061b9fb18571cf2441b2a7ee2419933ddaa423bc178672cd11e87911616d1")!

        do {
            let test = try builder.lockingScript(type: .p2pk, params: [pubKey])
            XCTAssertEqual(test, data)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testP2SH() {
        let data = Data(hex: "a9142a02dfd19c9108ad48878a01bfe53deaaf30cca487")!
        let pubKey = Data(hex: "2a02dfd19c9108ad48878a01bfe53deaaf30cca4")!

        do {
            let test = try builder.lockingScript(type: .p2sh, params: [pubKey])
            XCTAssertEqual(test, data)
        } catch {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testP2PKHSig() {
        let data = Data(hex: "483045022100b78dacbc598d414f29537e33b5e7b209ecde9074b5fb4e68f94e8f5cb88ee9ad02202ef04916e8c1caa8cdb739c9695a51eadeaef6fe8ff7e990cc9031b410a123cc012103ec6877e5c28e459ac4daa3222204e7eef4cb42825b6b43438aeea01dd525b24d")!
        let pubKeys = [Data(hex: "3045022100b78dacbc598d414f29537e33b5e7b209ecde9074b5fb4e68f94e8f5cb88ee9ad02202ef04916e8c1caa8cdb739c9695a51eadeaef6fe8ff7e990cc9031b410a123cc01")!,
                       Data(hex: "03ec6877e5c28e459ac4daa3222204e7eef4cb42825b6b43438aeea01dd525b24d")!]

        let test = builder.unlockingScript(params: pubKeys)
        XCTAssertEqual(test, data)
    }

}
