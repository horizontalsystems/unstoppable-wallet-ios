import XCTest
import Cuckoo
@testable import WalletKit

class ScriptTests: XCTestCase {
    private var data: Data!

    override func setUp() {
        data = Data(hex: "01234567")!
        super.setUp()
    }

    override func tearDown() {
        data = nil
        super.tearDown()
    }

    func testValidLength() {
        let script = Script(with: data, chunks: [])
        XCTAssertEqual(script.length, data.count)
    }

    func testValidateSuccess() {
        let script = Script(with: data, chunks: [Chunk(scriptData: data, index: 0, payloadRange: 1..<2), Chunk(scriptData: data, index: 2), Chunk(scriptData: data, index: 3)])

        do {
            try script.validate(opCodes: Data(bytes: [0x01, 0x45, 0x67]))
        } catch let error {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testValidateWrongLength() {
        let script = Script(with: data, chunks: [Chunk(scriptData: data, index: 2), Chunk(scriptData: data, index: 3)])

        do {
            try script.validate(opCodes: Data(bytes: [0x01, 0x45, 0x67]))
        } catch let error as ScriptError {
            XCTAssertEqual(error, ScriptError.wrongScriptLength)
        } catch {
            XCTFail("\(error) Exception Thrown")
        }
    }

    func testValidateWrongSequence() {
        let script = Script(with: data, chunks: [Chunk(scriptData: data, index: 0, payloadRange: 1..<2), Chunk(scriptData: data, index: 2), Chunk(scriptData: data, index: 3)])

        do {
            try script.validate(opCodes: Data(bytes: [0x07, 0x33, 0x67]))
        } catch let error as ScriptError {
            XCTAssertEqual(error, ScriptError.wrongSequence)
        } catch {
            XCTFail("\(error) Exception Thrown")
        }
    }

}
