import Foundation
import Testing
@testable import Unstoppable

struct PasskeyCborReaderTests {
    @Test func readsUnsignedImmediate() throws {
        var reader = PasskeyCborReader(data: Data([0x05]))
        try #expect(reader.readUnsigned() == 5)
    }

    @Test func readsUnsignedMultibyte() throws {
        var reader = PasskeyCborReader(data: Data([0x19, 0x12, 0x34]))
        try #expect(reader.readUnsigned() == 0x1234)
    }

    @Test func readsUnsignedU64() throws {
        var reader = PasskeyCborReader(data: Data([0x1B, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]))
        try #expect(reader.readUnsigned() == 0x0102_0304_0506_0708)
    }

    @Test func readsNegativeInt() throws {
        var r1 = PasskeyCborReader(data: Data([0x20]))
        try #expect(r1.readNegative() == -1)

        var r2 = PasskeyCborReader(data: Data([0x21]))
        try #expect(r2.readNegative() == -2)

        var r3 = PasskeyCborReader(data: Data([0x26]))
        try #expect(r3.readNegative() == -7)
    }

    @Test func readsSignedIntBothBranches() throws {
        var pos = PasskeyCborReader(data: Data([0x05]))
        try #expect(pos.readInt() == 5)

        var neg = PasskeyCborReader(data: Data([0x20]))
        try #expect(neg.readInt() == -1)
    }

    @Test func readsShortBytes() throws {
        var reader = PasskeyCborReader(data: Data([0x43, 0xAA, 0xBB, 0xCC]))
        try #expect(reader.readBytes() == Data([0xAA, 0xBB, 0xCC]))
    }

    @Test func readsLongerBytes() throws {
        let payload = Data(repeating: 0x42, count: 40)
        var reader = PasskeyCborReader(data: Data([0x58, 0x28]) + payload)
        try #expect(reader.readBytes() == payload)
    }

    @Test func readsString() throws {
        var reader = PasskeyCborReader(data: Data([0x63, 0x61, 0x62, 0x63]))
        try #expect(reader.readString() == "abc")
    }

    @Test func readsMapCount() throws {
        var empty = PasskeyCborReader(data: Data([0xA0]))
        try #expect(empty.readMapCount() == 0)

        var three = PasskeyCborReader(data: Data([0xA3]))
        try #expect(three.readMapCount() == 3)

        var sixteen = PasskeyCborReader(data: Data([0xB0]))
        try #expect(sixteen.readMapCount() == 16)
    }

    @Test func rejectsOversizedMap() throws {
        var reader = PasskeyCborReader(data: Data([0xB1]))
        #expect(throws: PasskeyCborReader.DecodeError.self) {
            try reader.readMapCount()
        }
    }

    @Test func rejectsReservedAdditionalInfo() throws {
        var reader = PasskeyCborReader(data: Data([0x1C]))
        #expect(throws: PasskeyCborReader.DecodeError.self) {
            try reader.readHeader()
        }
    }

    @Test func rejectsIndefiniteLength() throws {
        var reader = PasskeyCborReader(data: Data([0x1F]))
        #expect(throws: PasskeyCborReader.DecodeError.self) {
            try reader.readHeader()
        }
    }

    @Test func rejectsTruncatedHeader() throws {
        var reader = PasskeyCborReader(data: Data([0x19]))
        #expect(throws: PasskeyCborReader.DecodeError.self) {
            try reader.readUnsigned()
        }
    }

    @Test func rejectsTruncatedPayload() throws {
        var reader = PasskeyCborReader(data: Data([0x43, 0xAA]))
        #expect(throws: PasskeyCborReader.DecodeError.self) {
            try reader.readBytes()
        }
    }

    @Test func rejectsInvalidUtf8() throws {
        var reader = PasskeyCborReader(data: Data([0x61, 0xFF]))
        #expect(throws: PasskeyCborReader.DecodeError.self) {
            try reader.readString()
        }
    }

    @Test func rejectsUnexpectedMajorType() throws {
        // 0xA0 is a map; asking for unsigned should fail.
        var reader = PasskeyCborReader(data: Data([0xA0]))
        #expect(throws: PasskeyCborReader.DecodeError.self) {
            try reader.readUnsigned()
        }
    }

    @Test func skipsSimpleMap() throws {
        // {1: 2} followed by trailing 0xFF.
        var reader = PasskeyCborReader(data: Data([0xA1, 0x01, 0x02, 0xFF]))
        try reader.skip()
        #expect(reader.cursor == 3)
    }

    @Test func skipsNestedMap() throws {
        // {1: {2: 3}}
        var reader = PasskeyCborReader(data: Data([0xA1, 0x01, 0xA1, 0x02, 0x03]))
        try reader.skip()
        #expect(reader.cursor == 5)
    }

    @Test func skipsArrays() throws {
        // [1, 2, 3]
        var reader = PasskeyCborReader(data: Data([0x83, 0x01, 0x02, 0x03, 0xFF]))
        try reader.skip()
        #expect(reader.cursor == 4)
    }

    @Test func rejectsDeeplyNestedSkip() throws {
        // 8 nested single-element arrays trip the depth cap.
        let bytes = [UInt8](repeating: 0x81, count: 8) + [0x00]
        var reader = PasskeyCborReader(data: Data(bytes))
        #expect(throws: PasskeyCborReader.DecodeError.self) {
            try reader.skip()
        }
    }
}
