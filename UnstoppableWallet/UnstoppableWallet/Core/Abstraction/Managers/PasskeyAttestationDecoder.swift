import Foundation

// Decodes Apple platform authenticator's rawAttestationObject (CBOR) into a Registration.
// Reads only authData; attStmt and fmt are skipped. Extracts P-256 pubkey from COSE key.
// Trailing bytes after credentialPublicKey (ED-flag extensions) are ignored — forward-compat.
enum PasskeyAttestationDecoder {
    // COSE (RFC 8152) label, key-type and algorithm identifiers.
    private static let coseKeyTypeEc2: Int64 = 2
    private static let coseAlgEs256: Int64 = -7
    private static let coseCurveP256: Int64 = 1

    private static let coseLabelKty: Int64 = 1
    private static let coseLabelAlg: Int64 = 3
    private static let coseLabelCrv: Int64 = -1
    private static let coseLabelX: Int64 = -2
    private static let coseLabelY: Int64 = -3

    // authData binary layout (WebAuthn §6.1). AT = bit 6 in flags.
    private static let flagsOffset = 32
    private static let atFlagBit: UInt8 = 0x40
    private static let credentialIdLengthOffset = 53
    private static let credentialIdOffset = 55

    private static let coordinateByteLength = 32

    static func decode(rawAttestationObject: Data) throws -> SmartAccountPasskeyManager.Registration {
        var reader = PasskeyCborReader(data: rawAttestationObject)
        let rootCount = try reader.readMapCount()

        var authData: Data?
        for _ in 0 ..< rootCount {
            let key = try reader.readString()
            switch key {
            case "authData":
                authData = try reader.readBytes()
            default:
                try reader.skip()
            }
        }

        guard let authData else { throw DecodeError.missingAuthData }

        let (credentialID, coseBytes) = try parseAuthData(authData)
        let (publicKeyX, publicKeyY) = try decodeCoseKey(coseBytes)

        return SmartAccountPasskeyManager.Registration(
            credentialID: credentialID,
            publicKeyX: publicKeyX,
            publicKeyY: publicKeyY
        )
    }

    private static func parseAuthData(_ authData: Data) throws -> (credentialID: Data, coseBytes: Data) {
        // Need at least up to credentialIdLength (offset 53..<55).
        guard authData.count > credentialIdLengthOffset + 1 else { throw DecodeError.authDataTooShort }

        let flagsByte = authData[authData.startIndex + flagsOffset]
        guard flagsByte & atFlagBit != 0 else { throw DecodeError.missingATFlag }

        let hi = UInt16(authData[authData.startIndex + credentialIdLengthOffset])
        let lo = UInt16(authData[authData.startIndex + credentialIdLengthOffset + 1])
        let credentialIdLength = Int((hi << 8) | lo)

        let credStart = authData.startIndex + credentialIdOffset
        let credEnd = credStart + credentialIdLength
        guard credEnd <= authData.endIndex else { throw DecodeError.authDataTooShort }

        let credentialID = Data(authData[credStart ..< credEnd])
        let coseBytes = Data(authData[credEnd ..< authData.endIndex])

        return (credentialID, coseBytes)
    }

    private static func decodeCoseKey(_ data: Data) throws -> (x: Data, y: Data) {
        var reader = PasskeyCborReader(data: data)
        let count = try reader.readMapCount()

        var kty: Int64?
        var alg: Int64?
        var crv: Int64?
        var x: Data?
        var y: Data?

        for _ in 0 ..< count {
            let label = try reader.readInt()
            switch label {
            case coseLabelKty:
                kty = try reader.readInt()
            case coseLabelAlg:
                alg = try reader.readInt()
            case coseLabelCrv:
                crv = try reader.readInt()
            case coseLabelX:
                x = try reader.readBytes()
            case coseLabelY:
                y = try reader.readBytes()
            default:
                try reader.skip()
            }
        }

        guard let kty else { throw DecodeError.missingCoseKey }
        guard kty == coseKeyTypeEc2 else { throw DecodeError.unsupportedKeyType(kty) }
        guard let alg else { throw DecodeError.missingCoseKey }
        guard alg == coseAlgEs256 else { throw DecodeError.unsupportedAlgorithm(alg) }
        guard let crv else { throw DecodeError.missingCoseKey }
        guard crv == coseCurveP256 else { throw DecodeError.unsupportedCurve(crv) }
        guard let x else { throw DecodeError.missingX }
        guard x.count == coordinateByteLength else { throw DecodeError.invalidCoordinateLength }
        guard let y else { throw DecodeError.missingY }
        guard y.count == coordinateByteLength else { throw DecodeError.invalidCoordinateLength }

        return (x, y)
    }
}

extension PasskeyAttestationDecoder {
    enum DecodeError: Error {
        case missingAuthData
        case authDataTooShort
        case missingATFlag
        case missingCoseKey
        case unsupportedKeyType(Int64)
        case unsupportedAlgorithm(Int64)
        case unsupportedCurve(Int64)
        case missingX
        case missingY
        case invalidCoordinateLength
    }
}
