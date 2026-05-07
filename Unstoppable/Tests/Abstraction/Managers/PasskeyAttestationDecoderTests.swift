import Foundation
import Testing
@testable import Unstoppable

struct PasskeyAttestationDecoderTests {
    @Test func decodesValidSyntheticFixture() throws {
        let x = Data(repeating: 0xAA, count: 32)
        let y = Data(repeating: 0xBB, count: 32)
        let credId = Data(repeating: 0xCC, count: 16)
        let raw = buildAttestation(credentialId: credId, cose: validCose(x: x, y: y))

        let registration = try PasskeyAttestationDecoder.decode(rawAttestationObject: raw)

        #expect(registration.credentialID == credId)
        #expect(registration.publicKeyX == x)
        #expect(registration.publicKeyY == y)
    }

    @Test func acceptsEdFlagTrailingExtensions() throws {
        // Forward-compat: ED flag (bit 7) set + extra CBOR map appended after the COSE key.
        let trailingExtensions = Data([0xA1, 0x01, 0x02]) // {1: 2}
        let raw = buildAttestation(
            flags: 0x45 | 0x80,
            cose: validCose() + trailingExtensions
        )

        let registration = try PasskeyAttestationDecoder.decode(rawAttestationObject: raw)

        #expect(registration.publicKeyX.count == 32)
        #expect(registration.publicKeyY.count == 32)
    }

    @Test func rejectsMissingATFlag() {
        let raw = buildAttestation(flags: 0x01, cose: validCose())
        expectDecoderThrows(raw)
    }

    @Test func rejectsUnsupportedCurve() {
        // crv = 2 (P-384) instead of 1.
        let cose = customCose(kty: 2, alg: -7, crv: 2, x: Data(repeating: 0x11, count: 32), y: Data(repeating: 0x22, count: 32))
        let raw = buildAttestation(cose: cose)
        expectDecoderThrows(raw)
    }

    @Test func rejectsUnsupportedKeyType() {
        // kty = 3 (RSA) instead of 2.
        let cose = customCose(kty: 3, alg: -7, crv: 1, x: Data(repeating: 0x11, count: 32), y: Data(repeating: 0x22, count: 32))
        let raw = buildAttestation(cose: cose)
        expectDecoderThrows(raw)
    }

    @Test func rejectsUnsupportedAlgorithm() {
        // alg = -8 (EdDSA) instead of -7 (ES256).
        let cose = customCose(kty: 2, alg: -8, crv: 1, x: Data(repeating: 0x11, count: 32), y: Data(repeating: 0x22, count: 32))
        let raw = buildAttestation(cose: cose)
        expectDecoderThrows(raw)
    }

    @Test func rejectsShortCoordinate() {
        // X is only 16 bytes instead of 32.
        let cose = customCose(kty: 2, alg: -7, crv: 1, x: Data(repeating: 0x11, count: 16), y: Data(repeating: 0x22, count: 32))
        let raw = buildAttestation(cose: cose)
        expectDecoderThrows(raw)
    }

    @Test func rejectsMissingX() {
        var cose = Data([0xA4]) // map, 4 entries (no X)
        cose.append(contentsOf: [0x01, 0x02])
        cose.append(contentsOf: [0x03, 0x26])
        cose.append(contentsOf: [0x20, 0x01])
        cose.append(contentsOf: [0x22]) // label -3 (Y)
        cose.append(cborBstr(Data(repeating: 0x22, count: 32)))

        let raw = buildAttestation(cose: cose)
        expectDecoderThrows(raw)
    }

    @Test func rejectsTruncatedAuthData() {
        // AuthData with only rpIdHash + flags, nothing after.
        var authData = Data(repeating: 0, count: 32)
        authData.append(0x45) // flags with AT bit
        let raw = buildRawAttestation(authData: authData)
        expectDecoderThrows(raw)
    }

    @Test func rejectsOversizedCoseMap() {
        // COSE map claims 17 entries — exceeds cap.
        var cose = Data([0xB1]) // mt=5, info=17 → 17 entries
        for _ in 0 ..< 17 {
            cose.append(contentsOf: [0x01, 0x02])
        }
        let raw = buildAttestation(cose: cose)
        expectDecoderThrows(raw)
    }

    // MARK: - Helpers

    private func expectDecoderThrows(_ raw: Data) {
        #expect(throws: (any Error).self) {
            try PasskeyAttestationDecoder.decode(rawAttestationObject: raw)
        }
    }

    private func buildAttestation(
        flags: UInt8 = 0x45,
        credentialId: Data = Data(repeating: 0xCC, count: 16),
        cose: Data
    ) -> Data {
        var authData = Data()
        authData.append(Data(repeating: 0, count: 32)) // rpIdHash
        authData.append(flags)
        authData.append(Data(repeating: 0, count: 4)) // signCount
        authData.append(Data(repeating: 0, count: 16)) // AAGUID
        authData.append(UInt8((credentialId.count >> 8) & 0xFF))
        authData.append(UInt8(credentialId.count & 0xFF))
        authData.append(credentialId)
        authData.append(cose)
        return buildRawAttestation(authData: authData)
    }

    private func buildRawAttestation(authData: Data) -> Data {
        var raw = Data([0xA3]) // map, 3 entries
        raw.append(cborTstr("fmt"))
        raw.append(cborTstr("none"))
        raw.append(cborTstr("authData"))
        raw.append(cborBstr(authData))
        raw.append(cborTstr("attStmt"))
        raw.append(Data([0xA0])) // empty attStmt
        return raw
    }

    private func validCose(
        x: Data = Data(repeating: 0x11, count: 32),
        y: Data = Data(repeating: 0x22, count: 32)
    ) -> Data {
        customCose(kty: 2, alg: -7, crv: 1, x: x, y: y)
    }

    private func customCose(kty: Int64, alg: Int64, crv: Int64, x: Data, y: Data) -> Data {
        var cose = Data([0xA5]) // map, 5 entries
        cose.append(contentsOf: [0x01])
        cose.append(cborInt(kty))
        cose.append(contentsOf: [0x03])
        cose.append(cborInt(alg))
        cose.append(contentsOf: [0x20]) // label -1
        cose.append(cborInt(crv))
        cose.append(contentsOf: [0x21]) // label -2
        cose.append(cborBstr(x))
        cose.append(contentsOf: [0x22]) // label -3
        cose.append(cborBstr(y))
        return cose
    }

    private func cborInt(_ value: Int64) -> Data {
        if value >= 0 {
            return cborUnsigned(UInt64(value))
        } else {
            // Encoded value for negative: -1 - real = -1 - value (so value=-7 → encoded=6).
            let encoded = UInt64(-1 - value)
            let header: UInt8 = 0x20 // mt=1, info=0 slot
            if encoded < 24 { return Data([header | UInt8(encoded)]) }
            if encoded < 256 { return Data([0x38, UInt8(encoded)]) }
            fatalError("cborInt: negative value too large for test fixture")
        }
    }

    private func cborUnsigned(_ value: UInt64) -> Data {
        if value < 24 { return Data([UInt8(value)]) }
        if value < 256 { return Data([0x18, UInt8(value)]) }
        if value < 65536 {
            return Data([0x19, UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)])
        }
        fatalError("cborUnsigned: value too large for test fixture")
    }

    private func cborTstr(_ s: String) -> Data {
        let bytes = Data(s.utf8)
        var header = Data()
        if bytes.count < 24 {
            header.append(UInt8(0x60 | bytes.count))
        } else if bytes.count < 256 {
            header.append(0x78)
            header.append(UInt8(bytes.count))
        }
        return header + bytes
    }

    private func cborBstr(_ d: Data) -> Data {
        var header = Data()
        if d.count < 24 {
            header.append(UInt8(0x40 | d.count))
        } else if d.count < 256 {
            header.append(0x58)
            header.append(UInt8(d.count))
        } else if d.count < 65536 {
            header.append(0x59)
            header.append(UInt8((d.count >> 8) & 0xFF))
            header.append(UInt8(d.count & 0xFF))
        }
        return header + d
    }
}
