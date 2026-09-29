import Foundation
import MarketKit
import SwiftUI

public protocol ISendData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    var rateCoins: [Coin] { get }
    var customSendButtonTitle: String? { get }
    var amountAdjusted: Bool { get }
    func fields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField]
    func feeFields(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendField]
    func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew]
    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection]
}

public extension ISendData {
    var customSendButtonTitle: String? {
        nil
    }

    func fields(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> [SendField] {
        []
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
    // Divider after each field of a flow section except the last; nil puts an arrow between every two fields
    public let flowDividers: [FlowDivider]?

    public init(_ fields: [SendField], isMain: Bool = true, isFlow: Bool = false, isList: Bool = true, flowDividers: [FlowDivider]? = nil) {
        self.fields = fields
        self.isMain = isMain
        self.isFlow = isFlow
        self.isList = isList
        self.flowDividers = flowDividers
    }

    @MainActor @ViewBuilder var fieldList: some View {
        ForEach(fields.indices, id: \.self) { index in
            fields[index].listRow()
            if isFlow, index < (fields.count - 1) {
                switch flowDivider(after: index) {
                case .arrow: flowDivider
                case .line: HorizontalDivider()
                case .hidden: EmptyView()
                }
            }
        }
    }

    private func flowDivider(after index: Int) -> FlowDivider {
        guard let flowDividers else {
            return .arrow
        }

        return flowDividers.indices.contains(index) ? flowDividers[index] : .hidden
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

public extension SendDataSection {
    enum FlowDivider {
        case arrow
        case line
        case hidden
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
