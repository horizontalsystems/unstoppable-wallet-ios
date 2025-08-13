import Foundation

struct MultiSwapMainField: Identifiable {
    let title: String
    let infoDescription: InfoDescription?
    let value: String
    let valueLevel: ValueLevel
    let settingId: String?
    let modified: Bool

    init(title: String, infoDescription: InfoDescription? = nil, value: String, valueLevel: ValueLevel = .regular, settingId: String? = nil, modified: Bool = false) {
        self.title = title
        self.infoDescription = infoDescription
        self.value = value
        self.valueLevel = valueLevel
        self.settingId = settingId
        self.modified = modified
    }

    var id: String {
        title
    }
}

extension MultiSwapMainField {
    static func recipient(_ recipient: String, level: ValueLevel = .regular) -> Self {
        .init(
            title: "swap.recipient".localized,
            value: recipient,
            valueLevel: .regular
        )
    }
    
    static func slippage(_ slippage: Decimal) -> Self {
        .init(
            title: "swap.slippage".localized,
            value: "\(slippage.description)%",
            valueLevel: MultiSwapSlippage.validate(slippage: slippage).valueLevel
        )
    }
}
