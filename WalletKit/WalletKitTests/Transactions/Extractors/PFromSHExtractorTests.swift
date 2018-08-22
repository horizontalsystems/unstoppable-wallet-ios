import XCTest
import Cuckoo
@testable import WalletKit

class PFromSHExtractorTests: XCTestCase {

    private var extractor: ScriptExtractor!

    override func setUp() {
        super.setUp()

        extractor = PFromSHExtractor()
    }

    override func tearDown() {
        extractor = nil

        super.tearDown()
    }

    func testValidExtract() {
//        let data = Data(hex: "9100473044022051c7546ff919248badd1012317066cc0edd3e5f49050ac54ef52b66a8e80e17b02201dd65963551e0dc7d8ce5721fbd3125fa9272a98bad1ed5df91488a462eac1230147512103b4603330291721c0a8e9cae65124a7099ecf0df3b46921d0e30c4220597702cb2102b2ec7de7e811c05aaf8443e3810483d5dbcf671512d9999f9c9772b0ce9da47a52ae")!
//        let redeemScript = Data(hex: "512103b4603330291721c0a8e9cae65124a7099ecf0df3b46921d0e30c4220597702cb2102b2ec7de7e811c05aaf8443e3810483d5dbcf671512d9999f9c9772b0ce9da47a52ae")!
//
//        do {
//            let test = try extractor.extract(from: data)
//            XCTAssertEqual(test, redeemScript)
//        } catch let error {
//            XCTFail("\(error) Exception Thrown")
//        }
    }

    func testInvalidLength() {
//        let data = Data(hex: "76a914cbc20a7664f2f6945e5355aa427045bc15e7c6c77288ac")!
//
//        do {
//            _ = try extractor.extract(from: data)
//            XCTFail("No Exception Thrown")
//        } catch let error as ScriptError {
//            XCTAssertEqual(error, ScriptError.wrongScriptLength)
//        } catch {
//            XCTFail("Unknown exception thrown")
//        }
    }

    func testInvalidStartSequence() {
//        let data = Data(hex: "b9142a02dfd19c9108ad48878a01bfe53deaaf30cca487")!
//
//        do {
//            _ = try extractor.extract(from: data)
//            XCTFail("No Exception Thrown")
//        } catch let error as ScriptError {
//            XCTAssertEqual(error, ScriptError.wrongSequence)
//        } catch {
//            XCTFail("Unknown exception thrown")
//        }
    }

    func testInvalidFinishSequence() {
//        let data = Data(hex: "a9142a02dfd19c9108ad48878a01bfe53deaaf30cca490")!
//
//        do {
//            _ = try extractor.extract(from: data)
//            XCTFail("No Exception Thrown")
//        } catch let error as ScriptError {
//            XCTAssertEqual(error, ScriptError.wrongSequence)
//        } catch {
//            XCTFail("Unknown exception thrown")
//        }
    }

}
