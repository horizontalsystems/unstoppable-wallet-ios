import Foundation

/// LUD-01 bech32 decoder. BIP-173 algorithm with the LUD-01 relaxation: no 90-byte length cap.
///
/// `BitcoinCore.Bech32` (already transitively imported via BitcoinAdapter) implements the same
/// gen polynomial / charset / polymod / expandHrp, but `Bech32.decode()` enforces the BIP-173
/// 90-byte input cap which LUD-01 explicitly drops (LNURLs are typically 150–2000 bytes).
/// No way to bypass the cap through the public API, hence this dedicated decoder.
///
/// Verified against the LUD-01 example vector:
///   lnurl1dp68gurn8ghj7um9wfmxjcm99e3k7mf0v9cxj0m385ekvcenxc6r2c35xvukxefcv5mkvv34x5ekzd3ev56nyd3hxqurzepexejxxepnxscrvwfnv9nxzcn9xq6xyefhvgcxxcmyxymnserxfq
///   → https://service.com/api?q=3fc3645b439ce8e7f2553a69e5267081d96dcd340693afabe04be7b0ccd178df
enum Bech32Decoder {
    enum Error: Swift.Error {
        case invalidChar
        case invalidCase
        case missingSeparator
        case emptyHrp
        case checksumFailed
        case dataTooShort
        case nonUtf8Payload
    }

    private static let charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"

    static func decode(_ input: String) throws -> String {
        let lower = input.lowercased()
        let upper = input.uppercased()
        if input != lower, input != upper {
            throw Error.invalidCase
        }
        let normalized = lower

        guard let separatorIndex = normalized.lastIndex(of: "1") else {
            throw Error.missingSeparator
        }
        if separatorIndex == normalized.startIndex {
            throw Error.emptyHrp
        }

        let hrp = String(normalized[normalized.startIndex ..< separatorIndex])
        guard hrp.unicodeScalars.allSatisfy({ (33 ... 126).contains($0.value) }) else {
            throw Error.invalidChar
        }
        let dataPart = normalized[normalized.index(after: separatorIndex)...]
        guard dataPart.count >= 6 else {
            throw Error.dataTooShort
        }

        var values: [UInt8] = []
        values.reserveCapacity(dataPart.count)
        for ch in dataPart {
            guard let idx = charset.firstIndex(of: ch) else {
                throw Error.invalidChar
            }
            values.append(UInt8(charset.distance(from: charset.startIndex, to: idx)))
        }

        guard verifyChecksum(hrp: hrp, data: values) else {
            throw Error.checksumFailed
        }

        let payload = Array(values.dropLast(6))
        let bytes = try convertBits(payload, fromBits: 5, toBits: 8, pad: false)
        guard let result = String(bytes: bytes, encoding: .utf8) else {
            throw Error.nonUtf8Payload
        }
        return result
    }

    private static func hrpExpand(_ hrp: String) -> [UInt8] {
        let scalars = Array(hrp.unicodeScalars)
        var out: [UInt8] = []
        out.reserveCapacity(scalars.count * 2 + 1)
        for s in scalars {
            out.append(UInt8(s.value >> 5))
        }
        out.append(0)
        for s in scalars {
            out.append(UInt8(s.value & 31))
        }
        return out
    }

    private static func polymod(_ values: [UInt8]) -> UInt32 {
        let gen: [UInt32] = [0x3B6A_57B2, 0x2650_8E6D, 0x1EA1_19FA, 0x3D42_33DD, 0x2A14_62B3]
        var chk: UInt32 = 1
        for v in values {
            let b = chk >> 25
            chk = ((chk & 0x1FFFFFF) << 5) ^ UInt32(v)
            for i in 0 ..< 5 {
                if (b >> i) & 1 == 1 {
                    chk ^= gen[i]
                }
            }
        }
        return chk
    }

    private static func verifyChecksum(hrp: String, data: [UInt8]) -> Bool {
        polymod(hrpExpand(hrp) + data) == 1
    }

    private static func convertBits(_ data: [UInt8], fromBits: Int, toBits: Int, pad: Bool) throws -> [UInt8] {
        var acc = 0
        var bits = 0
        var out: [UInt8] = []
        let maxv = (1 << toBits) - 1
        let maxAcc = (1 << (fromBits + toBits - 1)) - 1
        for v in data {
            let value = Int(v)
            if value < 0 || (value >> fromBits) != 0 { throw Error.invalidChar }
            acc = ((acc << fromBits) | value) & maxAcc
            bits += fromBits
            while bits >= toBits {
                bits -= toBits
                out.append(UInt8((acc >> bits) & maxv))
            }
        }
        if pad {
            if bits > 0 {
                out.append(UInt8((acc << (toBits - bits)) & maxv))
            }
        } else if bits >= fromBits || ((acc << (toBits - bits)) & maxv) != 0 {
            throw Error.checksumFailed
        }
        return out
    }
}
