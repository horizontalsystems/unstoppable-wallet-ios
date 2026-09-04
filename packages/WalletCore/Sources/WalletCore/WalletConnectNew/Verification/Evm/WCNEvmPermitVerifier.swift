import BigInt
import EvmKit

// EIP-2612 Permit and Permit2 PermitSingle with an unlimited amount: nothing hits the chain now, so warn loudly
class WCNEvmPermitVerifier: IWCNVerifier {
    static let permit2Contract = "0x000000000022D473030F116dDEE9F6B43aC78BA3"
    private static let maxUint256 = BigUInt(2).power(256) - 1
    private static let maxUint160 = BigUInt(2).power(160) - 1

    func handles(_ context: WCNVerificationContext) -> Bool {
        (context.payload as? WCNEvmSignMessagePayload)?.typedData != nil
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        guard let payload = context.payload as? WCNEvmSignMessagePayload, let typedData = payload.typedData,
              let message = typedData.message.objectValue
        else {
            return .pass
        }

        switch typedData.primaryType {
        case "Permit":
            guard let spender = message["spender"]?.stringValue, let value = Self.amount(message["value"]) else { return .pass }
            return value >= Self.maxUint256 ? .caution(reason: .permitUnlimitedAllowance(spender: spender)) : .pass

        case "PermitSingle":
            guard payload.typedDataDomain?.verifyingContract?.lowercased() == Self.permit2Contract.lowercased(),
                  let spender = message["spender"]?.stringValue,
                  let amount = Self.amount(message["details"]?.objectValue?["amount"])
            else { return .pass }
            return amount >= Self.maxUint160 ? .caution(reason: .permitUnlimitedAllowance(spender: spender)) : .pass

        default:
            return .pass
        }
    }

    private static func amount(_ json: JSON?) -> BigUInt? {
        if let number = json?.doubleValue {
            return BigUInt(number)
        }
        guard let string = json?.stringValue else {
            return nil
        }
        return string.hasPrefix("0x") ? BigUInt(string.dropFirst(2), radix: 16) : BigUInt(string)
    }
}
