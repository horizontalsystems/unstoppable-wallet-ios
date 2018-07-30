import XCTest
import Cuckoo
import RealmSwift
import BigInt
@testable import WalletKit

class DifficultyEncoderTests: XCTestCase {

    private var difficultyEncoder: DifficultyEncoder!

    override func setUp() {
        super.setUp()

        difficultyEncoder = DifficultyEncoder()
    }

    override func tearDown() {
        difficultyEncoder = nil

        super.tearDown()
    }

    func testEncodeCompact() {
        let difficulty: BigInt = BigInt("1234560000", radix: 16)!
        let representation: Int = 0x05123456

        XCTAssertEqual(difficultyEncoder.encodeCompact(from: difficulty), representation)
    }

    func testEncodeCompact_firstZero() {
        let difficulty: BigInt = BigInt("c0de000000", radix: 16)!
        let representation: Int = 0x0600c0de

        XCTAssertEqual(difficultyEncoder.encodeCompact(from: difficulty), representation)
    }

    func testEncodeCompact_negativeSign() {
        let difficulty: BigInt = BigInt("-40de000000", radix: 16)!
        let representation: Int = 0x05c0de00

        XCTAssertEqual(difficultyEncoder.encodeCompact(from: difficulty), representation)
    }

    func testDecodeCompact() {
        let difficulty: BigInt = BigInt("1234560000", radix: 16)!
        let representation: Int = 0x05123456

        XCTAssertEqual(difficultyEncoder.decodeCompact(bits: representation), difficulty)
    }

    func testDecodeCompact_firstZero() {
        let difficulty: BigInt = BigInt("c0de000000", radix: 16)!
        let representation: Int = 0x0600c0de

        XCTAssertEqual(difficultyEncoder.decodeCompact(bits: representation), difficulty)
    }

    func testDecodeCompact_negativeSign() {
        let difficulty: BigInt = BigInt("-40de000000", radix: 16)!
        let representation: Int = 0x05c0de00

        XCTAssertEqual(difficultyEncoder.decodeCompact(bits: representation), difficulty)
    }

}
