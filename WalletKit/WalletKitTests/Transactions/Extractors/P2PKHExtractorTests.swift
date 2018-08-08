import XCTest
import Cuckoo
@testable import WalletKit

class P2PKHExtractorTests: XCTestCase {

    private var extractor: ScriptExtractor!

    override func setUp() {
        super.setUp()

        extractor = P2PKHExtractor()
    }

    override func tearDown() {
        extractor = nil

        super.tearDown()
    }

    func testValidExtract() {
        let data = Data(hex: "76a914cbc20a7664f2f69e5355aa427045bc15e7c6c77288ac")!
        let pubKey = Data(hex: "cbc20a7664f2f69e5355aa427045bc15e7c6c772")!

        do {
            let test = try extractor.extract(from: data)
            XCTAssertEqual(test, pubKey)
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testInvalidLength() {
        let data = Data(hex: "76a914cbc20a7664f2f6945e5355aa427045bc15e7c6c77288ac")!

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
        let data = Data(hex: "77a914cbc20a7664f2f6945e5355aa4270bc15e7c6c77288ac")!

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
        let data = Data(hex: "76a914cbc20a7664f2f6945e5355aa4270bc15e7c6c77288a3")!

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
