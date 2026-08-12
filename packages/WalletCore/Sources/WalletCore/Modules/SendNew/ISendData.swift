import Foundation
import MarketKit
import SwiftUI

public protocol ISendData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    var rateCoins: [Coin] { get }
    var customSendButtonTitle: String? { get }
    // The fee rows alone, so a decorator can splice them into a section of its own instead of
    // reusing `sections(...)` wholesale — those render the whole transfer, which a decorated send
    // must present differently.
    func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField]
    // True when the handler silently reduced the transfer amount to fit the balance.
    var amountAdjusted: Bool { get }
    func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew]
    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection]
}

public extension ISendData {
    var customSendButtonTitle: String? {
        nil
    }

    func feeFields(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendField] {
        []
    }

    var amountAdjusted: Bool {
        false
    }

    internal func flowSection(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> (SendField, SendField)? {
        nil
    }
}

public struct SendDataSection {
    public let fields: [SendField]
    public let isMain: Bool
    public let isFlow: Bool
    public let isList: Bool

    public init(_ fields: [SendField], isMain: Bool = true, isFlow: Bool = false, isList: Bool = true) {
        self.fields = fields
        self.isMain = isMain
        self.isFlow = isFlow
        self.isList = isList
    }

    @MainActor @ViewBuilder var fieldList: some View {
        ForEach(fields.indices, id: \.self) { index in
            fields[index].listRow()
            if isFlow, index < (fields.count - 1) {
                flowDivider
            }
        }
    }

    @MainActor @ViewBuilder private var flowDivider: some View {
        HorizontalDivider()
            .overlay(
                Circle()
                    .fill(Color.themeLawrence)
                    .frame(width: 20, height: 20)
                    .overlay(
                        ThemeImage("arrow_m_down", size: .iconSize20)
                    )
            )
    }
}

extension [SendDataSection] {
    @MainActor @ViewBuilder var sectionViews: some View {
        if !isEmpty {
            ForEach(indices, id: \.self) { sectionIndex in
                let section = self[sectionIndex]

                if !section.fields.isEmpty {
                    if section.isList {
                        ListSection {
                            VStack(spacing: 0) {
                                section.fieldList
                            }
                            .padding(.vertical, section.isMain ? 0 : 8)
                        }
                    } else {
                        section.fieldList
                    }
                }
            }
        }
    }
}
