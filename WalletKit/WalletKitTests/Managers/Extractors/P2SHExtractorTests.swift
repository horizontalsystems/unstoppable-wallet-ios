import XCTest
import Cuckoo
@testable import WalletKit

class P2SHExtractorTests: XCTestCase {

    private var extractor: ScriptExtractor!

    override func setUp() {
        super.setUp()

        extractor = P2SHExtractor()
    }

    override func tearDown() {
        extractor = nil

        super.tearDown()
    }

    func testValidExtract() {
        let data = Data(hex: "a9142a02dfd19c9108ad48878a01bfe53deaaf30cca487")!
        let pubKey = Data(hex: "2a02dfd19c9108ad48878a01bfe53deaaf30cca4")!

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
            let test = try extractor.extract(from: data)
            XCTFail("No Exception Thrown")
        } catch let error as ScriptExtractorError {
            XCTAssertEqual(error, ScriptExtractorError.wrongScriptLength)
        } catch {
            XCTFail("Unknown exception thrown")
        }
    }

    func testInvalidStartSequence() {
        let data = Data(hex: "b9142a02dfd19c9108ad48878a01bfe53deaaf30cca487")!

        do {
            let test = try extractor.extract(from: data)
            XCTFail("No Exception Thrown")
        } catch let error as ScriptExtractorError {
            XCTAssertEqual(error, ScriptExtractorError.wrongSequence)
        } catch {
            XCTFail("Unknown exception thrown")
        }
    }

    func testInvalidFinishSequence() {
        let data = Data(hex: "a9142a02dfd19c9108ad48878a01bfe53deaaf30cca490")!

        do {
            let test = try extractor.extract(from: data)
            XCTFail("No Exception Thrown")
        } catch let error as ScriptExtractorError {
            XCTAssertEqual(error, ScriptExtractorError.wrongSequence)
        } catch {
            XCTFail("Unknown exception thrown")
        }
    }

}
