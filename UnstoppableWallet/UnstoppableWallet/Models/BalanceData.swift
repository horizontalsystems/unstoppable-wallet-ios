import Foundation

class BalanceData: Codable, Equatable {
    let available: Decimal

    enum CodingKeys: String, CodingKey {
        case available
    }

    init(available: Decimal) {
        self.available = available
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(available, forKey: .available)
    }

    var balanceTotal: Decimal {
        available
    }

    var customStates: [CustomState] {
        []
    }

    static func == (lhs: BalanceData, rhs: BalanceData) -> Bool {
        lhs.available == rhs.available
    }
}

extension BalanceData {
    private static var types: [Decodable.Type] { [VerifiedBalanceData.self, LockedBalanceData.self] }

    static func instance(data: Data) throws -> BalanceData {
        let decoder = JSONDecoder()
        for type in types {
            if let decoded = try? decoder.decode(type, from: data),
               let instance = decoded as? BalanceData
            {
                return instance
            }
        }
        return try decoder.decode(BalanceData.self, from: data)
    }

    struct CustomState {
        let title: String
        let value: Decimal
        let infoTitle: String
        let infoDescription: String
    }
}

class LockedBalanceData: BalanceData {
    let locked: Decimal
    let notRelayed: Decimal

    init(available: Decimal, locked: Decimal = 0, notRelayed: Decimal = 0) {
        self.locked = locked
        self.notRelayed = notRelayed
        super.init(available: available)
    }

    enum CodingKeys: String, CodingKey {
        case locked, notRelayed
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        locked = try container.decode(Decimal.self, forKey: .locked)
        notRelayed = try container.decode(Decimal.self, forKey: .notRelayed)

        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(locked, forKey: .locked)
        try container.encode(notRelayed, forKey: .notRelayed)
    }

    override var balanceTotal: Decimal {
        super.balanceTotal + locked + notRelayed
    }

    override var customStates: [CustomState] {
        var states = super.customStates
        if !locked.isZero {
            states.append(
                CustomState(
                    title: "balance.token.locked".localized,
                    value: locked,
                    infoTitle: "balance.token.locked.info.title".localized,
                    infoDescription: "balance.token.locked.info.description".localized
                )
            )
        }
        if !notRelayed.isZero {
            states.append(
                CustomState(
                    title: "balance.token.not_relayed".localized,
                    value: notRelayed,
                    infoTitle: "balance.token.not_relayed.info.title".localized,
                    infoDescription: "balance.token.not_relayed.info.description".localized
                )
            )
        }
        return states
    }

    static func == (lhs: LockedBalanceData, rhs: LockedBalanceData) -> Bool {
        lhs.available == rhs.available && lhs.locked == rhs.locked && lhs.notRelayed == rhs.notRelayed
    }
}

class VerifiedBalanceData: BalanceData {
    let fullBalance: Decimal

    override var balanceTotal: Decimal { super.balanceTotal }

    init(fullBalance: Decimal, available: Decimal) {
        self.fullBalance = fullBalance
        super.init(available: available)
    }

    enum CodingKeys: String, CodingKey {
        case full
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fullBalance = try container.decode(Decimal.self, forKey: .full)

        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fullBalance, forKey: .full)
    }

    override var customStates: [CustomState] {
        var states = super.customStates
        let processingBalance = fullBalance - available
        if !processingBalance.isZero {
            states.append(
                CustomState(
                    title: "balance.token.processing".localized,
                    value: processingBalance,
                    infoTitle: "balance.token.processing.info.title".localized,
                    infoDescription: "balance.token.processing.info.description".localized
                )
            )
        }
        return states
    }
}

class ZCashVerifiedBalanceData: VerifiedBalanceData {
    static let empty = ZCashVerifiedBalanceData(fullBalance: 0, available: 0, transparent: 0)
    let transparent: Decimal

    override var balanceTotal: Decimal { super.balanceTotal }

    init(fullBalance: Decimal, available: Decimal, transparent: Decimal) {
        self.transparent = transparent
        super.init(fullBalance: fullBalance, available: available)
    }

    enum CodingKeys: String, CodingKey {
        case transparent
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        transparent = try container.decode(Decimal.self, forKey: .transparent)

        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(transparent, forKey: .transparent)
    }

    override var customStates: [CustomState] {
        var states = super.customStates
        if transparent > ZcashAdapter.minimalThreshold {
            states.append(
                CustomState(
                    title: "balance.token.transparent".localized,
                    value: transparent,
                    infoTitle: "balance.token.transparent.info.title".localized,
                    infoDescription: "balance.token.transparent.info.description".localized
                )
            )
        }
        return states
    }
}

// TODO: implement when will be needed
//    let staked: Decimal
//    let frozen: Decimal
//    CustomState(
//            title: "balance.token.staked".localized,
//            value: item.balanceData.staked,
//            infoTitle: "balance.token.staked.info.title".localized,
//            infoDescription: "balance.token.staked.info.description".localized
//    ),
//    CustomState(
//            title: "balance.token.frozen".localized,
//            value: item.balanceData.frozen,
//            infoTitle: "balance.token.frozen.info.title".localized,
//            infoDescription: "balance.token.frozen.info.description".localized
//    ),
