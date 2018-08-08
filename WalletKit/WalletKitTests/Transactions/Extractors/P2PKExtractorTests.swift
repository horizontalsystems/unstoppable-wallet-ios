import XCTest
import Cuckoo
@testable import WalletKit

class P2PKExtractorTests: XCTestCase {

    private var extractor: ScriptExtractor!

    override func setUp() {
        super.setUp()

        extractor = P2PKExtractor()
    }

    override func tearDown() {
        extractor = nil

        super.tearDown()
    }

    func testValidExtract() {
        let data = Data(hex: "21030e7061b9fb18571cf2441b2a7ee2419933ddaa423bc178672cd11e87911616d1ac")!
        let pubKey = Data(hex: "030e7061b9fb18571cf2441b2a7ee2419933ddaa423bc178672cd11e87911616d1")!

        do {
            let test = try extractor.extract(from: data)
            XCTAssertEqual(test, pubKey)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testInvalidLength() {
        let data = Data(hex: "21a914cbc20a7664f2f6945e5355aa427045bc15e7c6c77288ac")!

        do {
            _ = try extractor.extract(from: data)
            XCTFail("No Exception Thrown")
        } catch let error as ScriptExtractorError {
            XCTAssertEqual(error, ScriptExtractorError.wrongScriptLength)
        } catch {
            XCTFail("Unknown exception thrown")
        }
    }

    func testInvalidStartSequence() {
        let data = Data(hex: "f1030e7061b9fb18571cf2441b2a7ee2419933ddaa423bc178672cd11e87911616d1ac")!

        do {
            _ = try extractor.extract(from: data)
            XCTFail("No Exception Thrown")
        } catch let error as ScriptExtractorError {
            XCTAssertEqual(error, ScriptExtractorError.wrongSequence)
        } catch {
            XCTFail("Unknown exception thrown")
        }
    }

    func testInvalidFinishSequence() {
        let data = Data(hex: "21030e7061b9fb18571cf2441b2a7ee2419933ddaa423bc178672cd11e87911616d1ee")!

        do {
            _ = try extractor.extract(from: data)
            XCTFail("No Exception Thrown")
        } catch let error as ScriptExtractorError {
            XCTAssertEqual(error, ScriptExtractorError.wrongSequence)
        } catch {
            XCTFail("Unknown exception thrown")
        }
    }

}
