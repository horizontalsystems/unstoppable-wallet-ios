import Foundation
import WalletCore

struct NftAppValue: IAppValue {
    let nftUidValue: NftUid
    let tokenName: String?
    let tokenSymbol: String?

    init(nftUid: NftUid, tokenName: String?, tokenSymbol: String?) {
        nftUidValue = nftUid
        self.tokenName = tokenName
        self.tokenSymbol = tokenSymbol
    }

    var name: String { tokenName.map { "\($0) #\(nftUidValue.tokenId)" } ?? "#\(nftUidValue.tokenId)" }
    var code: String { tokenSymbol ?? "NFT" }

    func isSameKind(as other: any IAppValue) -> Bool {
        (other as? NftAppValue).map { $0.nftUidValue == nftUidValue } ?? false
    }

    func formattedFull(value: Decimal, signType: ValueFormatter.SignType, showCode _: Bool) -> String? {
        "\(Self.sign(for: value, signType: signType))\(value) \(code)"
    }

    func formattedShort(value: Decimal, signType: ValueFormatter.SignType) -> String? {
        "\(Self.sign(for: value, signType: signType))\(value) \(code)"
    }

    private static func sign(for value: Decimal, signType: ValueFormatter.SignType) -> String {
        guard !value.isZero else { return "" }
        let sign = value.isSignMinus ? "-" : "+"
        switch signType {
        case .never: return ""
        case .always: return sign
        case .auto: return value.isSignMinus ? sign : ""
        }
    }

    func isMaxValue(value _: Decimal) -> Bool { false }
}
