import BigInt
import EvmKit
import Foundation
import HsExtensions

/// Pimlico SingletonPaymaster v0.6 wire-format decoder.
///
/// Layout: paymaster(20) | mode+allowAllBundlers(1) | erc20Config | signature(64/65)
/// erc20Config = flags(1) | validUntil(6) | validAfter(6) | token(20)
///             | postOpGas(16) | exchangeRate(32) | paymasterValidationGasLimit(16)
///             | treasury(20) | optional preFund/constantFee/recipient
enum Erc20PaymasterAndData {
    struct Parsed {
        let paymaster: EvmKit.Address
        let combinedByte: UInt8
        let mode: UInt8
        let allowAllBundlers: Bool
        let erc20Flags: UInt8
        let constantFeePresent: Bool
        let recipientPresent: Bool
        let preFundPresent: Bool
        let validUntil: BigUInt
        let validAfter: BigUInt
        let token: EvmKit.Address
        let postOpGas: BigUInt
        let exchangeRate: BigUInt
        let paymasterValidationGasLimit: BigUInt
        let treasury: EvmKit.Address
        let preFundInToken: BigUInt
        let constantFee: BigUInt
        let recipient: EvmKit.Address?
        let signatureBytes: Int

        var modeName: String {
            switch mode {
            case 0: return "verifying"
            case 1: return "erc20"
            default: return "unknown(\(mode))"
            }
        }
    }

    static func parse(_ data: Data) -> Parsed? {
        guard data.count >= 20 + 1 + 117 else {
            return nil
        }

        let paymaster = EvmKit.Address(raw: data.subdata(in: 0 ..< 20))
        let combinedByte = data[20]
        let mode = combinedByte >> 1
        let allowAllBundlers = (combinedByte & 0x01) != 0
        guard mode == 1 else {
            return nil
        }

        var offset = 21
        let erc20Flags = data[offset]
        let constantFeePresent = (erc20Flags & 0x01) != 0
        let recipientPresent = (erc20Flags & 0x02) != 0
        let preFundPresent = (erc20Flags & 0x04) != 0
        offset += 1

        guard data.count >= offset + 6 + 6 + 20 + 16 + 32 + 16 + 20 else {
            return nil
        }

        let validUntil = uint(data: data.subdata(in: offset ..< offset + 6))
        offset += 6
        let validAfter = uint(data: data.subdata(in: offset ..< offset + 6))
        offset += 6
        let token = EvmKit.Address(raw: data.subdata(in: offset ..< offset + 20))
        offset += 20
        let postOpGas = uint(data: data.subdata(in: offset ..< offset + 16))
        offset += 16
        let exchangeRate = uint(data: data.subdata(in: offset ..< offset + 32))
        offset += 32
        let paymasterValidationGasLimit = uint(data: data.subdata(in: offset ..< offset + 16))
        offset += 16
        let treasury = EvmKit.Address(raw: data.subdata(in: offset ..< offset + 20))
        offset += 20

        var preFundInToken = BigUInt(0)
        if preFundPresent {
            guard data.count >= offset + 16 else { return nil }
            preFundInToken = uint(data: data.subdata(in: offset ..< offset + 16))
            offset += 16
        }

        var constantFee = BigUInt(0)
        if constantFeePresent {
            guard data.count >= offset + 16 else { return nil }
            constantFee = uint(data: data.subdata(in: offset ..< offset + 16))
            offset += 16
        }

        var recipient: EvmKit.Address?
        if recipientPresent {
            guard data.count >= offset + 20 else { return nil }
            recipient = EvmKit.Address(raw: data.subdata(in: offset ..< offset + 20))
            offset += 20
        }

        let signatureBytes = data.count - offset
        guard signatureBytes == 64 || signatureBytes == 65 else {
            return nil
        }

        return Parsed(
            paymaster: paymaster,
            combinedByte: combinedByte,
            mode: mode,
            allowAllBundlers: allowAllBundlers,
            erc20Flags: erc20Flags,
            constantFeePresent: constantFeePresent,
            recipientPresent: recipientPresent,
            preFundPresent: preFundPresent,
            validUntil: validUntil,
            validAfter: validAfter,
            token: token,
            postOpGas: postOpGas,
            exchangeRate: exchangeRate,
            paymasterValidationGasLimit: paymasterValidationGasLimit,
            treasury: treasury,
            preFundInToken: preFundInToken,
            constantFee: constantFee,
            recipient: recipient,
            signatureBytes: signatureBytes
        )
    }

    private static func uint(data: Data) -> BigUInt {
        BigUInt(data.hs.hex, radix: 16) ?? 0
    }
}
