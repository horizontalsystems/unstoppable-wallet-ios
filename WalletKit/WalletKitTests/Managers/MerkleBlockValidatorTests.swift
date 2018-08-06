import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class MerkleBlockValidatorTests: XCTestCase {
    private var validator: MerkleBlockValidator!
    private var blockHeader: BlockHeader!
    private var totalTransactions: UInt32!
    private var numberOfHashes: VarInt!
    private var hashes: [Data]!
    private var numberOfFlags: VarInt!
    private var flags: [UInt8]!


    override func setUp() {
        super.setUp()

        blockHeader = BlockHeader()
        blockHeader.merkleRoot = Data(hex: "2368b4465fe95716f7e8d510eafb26ee72cb843610fe0f38cfdc60561e0b50b2")!

        totalTransactions = 309
        numberOfHashes = 10

        hashes = [
            Data(hex: "c6232bba11b7b068995d7e26f59fb46403b9307886f0dfbeae01b075200a43c2")!,
            Data(hex: "7d3543eb3166350dd495812c3fb4fb0febc0f3a862910e29d2045bea08f1de67")!,
            Data(hex: "16b57ae681df96435c030f799317eab55deaf4258d4de629f18dbeb8534a6fa5")!,
            Data(hex: "175041d97932180ab5c280f809a46049f4149f2539db80223ac132898de33e8c")!,
            Data(hex: "68fc70737ef1a48ca9891aff40b5ce4d8f8013e1cc2371f96b3e628aa68651a8")!,
            Data(hex: "24ebddeb692ab96a6542c421fb505c7243c61b77125c703be89a25f4e9a163ed")!,
            Data(hex: "05e2281bb57a5f4d1e86d40cbafbc6911138113859799d293e031d335de82088")!,
            Data(hex: "0353c6fc93463d35e6ed4292d5b6709414727a443f1a829a1dab4acb6a54de68")!,
            Data(hex: "feaa4182afe5e1542a6a27a6a933c7c80471636aa9477685dcd7aa4f18722a35")!,
            Data(hex: "8c6e45e3341a18c53b2f40ca31eb4f59ff43240ad6a9221743cf856cb015bfda")!
        ]

        numberOfFlags = 3
        flags = [223, 22, 0]

        validator = MerkleBlockValidator()
    }

    override func tearDown() {
        super.tearDown()
    }

    private func getSampleMessage() -> MerkleBlockMessage {
        return MerkleBlockMessage(
                blockHeader: blockHeader, totalTransactions: totalTransactions,
                numberOfHashes: numberOfHashes, hashes: hashes, numberOfFlags: numberOfFlags, flags: flags
        )
    }


    func testValidMerkleBlock() {
        do {
            try validator.validate(message: getSampleMessage())
        } catch {
            print(error)
            XCTFail("Should be valid")
        }

        XCTAssertEqual(validator.txIds.count, 1)
        XCTAssertEqual(validator.txIds[0], hashes[3])
    }

    func testTxIdsClearedFirst() {
        do {
            try validator.validate(message: getSampleMessage())
            try validator.validate(message: getSampleMessage())
        } catch {
            print(error)
            XCTFail("Should be valid")
        }

        XCTAssertEqual(validator.txIds.count, 1)
        XCTAssertEqual(validator.txIds[0], hashes[3])
    }

    func testWrongMerkleRoot() {
        blockHeader = BlockHeader()
        blockHeader.merkleRoot = Data(hex: "0000000000000000000000000000000000000000000000000000000000000001")!

        var caught = false
        do {
            try validator.validate(message: getSampleMessage())
        } catch let error as MerkleBlockValidator.ValidationError {
            caught = true
            XCTAssertEqual(error, MerkleBlockValidator.ValidationError.wrongMerkleRoot)
        } catch {
            XCTFail("Unknown Exception")
        }

        if !caught {
            XCTFail("Should Throw Exception")
        }
    }

    func testNoTransactions() {
        totalTransactions = 0

        var caught = false
        do {
            try validator.validate(message: getSampleMessage())
        } catch let error as MerkleBlockValidator.ValidationError {
            caught = true
            XCTAssertEqual(error, MerkleBlockValidator.ValidationError.noTransactions)
        } catch {
            XCTFail("Unknown Exception")
        }

        if !caught {
            XCTFail("Should Throw Exception")
        }
    }

    func testTooManyTransactions() {
        totalTransactions = MerkleBlockValidator.MAX_BLOCK_SIZE / 60 + 1

        var caught = false
        do {
            try validator.validate(message: getSampleMessage())
        } catch let error as MerkleBlockValidator.ValidationError {
            caught = true
            XCTAssertEqual(error, MerkleBlockValidator.ValidationError.tooManyTransactions)
        } catch {
            XCTFail("Unknown Exception")
        }

        if !caught {
            XCTFail("Should Throw Exception")
        }
    }

    func testMoreHashesThanTransactions() {
        totalTransactions = 8

        var caught = false
        do {
            try validator.validate(message: getSampleMessage())
        } catch let error as MerkleBlockValidator.ValidationError {
            caught = true
            XCTAssertEqual(error, MerkleBlockValidator.ValidationError.moreHashesThanTransactions)
        } catch {
            XCTFail("Unknown Exception")
        }

        if !caught {
            XCTFail("Should Throw Exception")
        }
    }

    func testMatchedBitsFewerThanHashes() {
        flags = [200]

        var caught = false
        do {
            try validator.validate(message: getSampleMessage())
        } catch let error as MerkleBlockValidator.ValidationError {
            caught = true
            XCTAssertEqual(error, MerkleBlockValidator.ValidationError.matchedBitsFewerThanHashes)
        } catch {
            XCTFail("Unknown Exception")
        }

        if !caught {
            XCTFail("Should Throw Exception")
        }
    }

    func testUnnecessaryBits() {
        flags = [223, 22, 0, 1]

        var caught = false
        do {
            try validator.validate(message: getSampleMessage())
        } catch let error as MerkleBlockValidator.ValidationError {
            caught = true
            XCTAssertEqual(error, MerkleBlockValidator.ValidationError.unnecessaryBits)
        } catch {
            XCTFail("Unknown Exception")
        }

        if !caught {
            XCTFail("Should Throw Exception")
        }
    }

    func testNotEnoughBits() {
        flags = [223, 22]

        var caught = false
        do {
            try validator.validate(message: getSampleMessage())
        } catch let error as MerkleBlockValidator.ValidationError {
            caught = true
            XCTAssertEqual(error, MerkleBlockValidator.ValidationError.notEnoughBits)
        } catch {
            XCTFail("Unknown Exception")
        }

        if !caught {
            XCTFail("Should Throw Exception")
        }
    }

    func testNotEnoughHashes() {
        flags = [223, 22, 5]

        var caught = false
        do {
            try validator.validate(message: getSampleMessage())
        } catch let error as MerkleBlockValidator.ValidationError {
            caught = true
            XCTAssertEqual(error, MerkleBlockValidator.ValidationError.notEnoughHashes)
        } catch {
            XCTFail("Unknown Exception")
        }

        if !caught {
            XCTFail("Should Throw Exception")
        }
    }

    func testDuplicatedLeftOrRightBranches() {
        hashes[3] = Data(hex: "16b57ae681df96435c030f799317eab55deaf4258d4de629f18dbeb8534a6fa5")!

        var caught = false
        do {
            try validator.validate(message: getSampleMessage())
        } catch let error as MerkleBlockValidator.ValidationError {
            caught = true
            XCTAssertEqual(error, MerkleBlockValidator.ValidationError.duplicatedLeftOrRightBranches)
        } catch {
            XCTFail("Unknown Exception")
        }

        if !caught {
            XCTFail("Should Throw Exception")
        }
    }

}
