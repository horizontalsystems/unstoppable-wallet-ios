import Foundation
import MarketKit
import SwiftUI

protocol ISendData {
    var feeData: FeeData? { get }
    var canSend: Bool { get }
    var rateCoins: [Coin] { get }
    var customSendButtonTitle: String? { get }
    func cautions(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [CautionNew]
    func sections(baseToken: Token, currency: Currency, rates: [String: Decimal]) -> [SendDataSection]
}

extension ISendData {
    var customSendButtonTitle: String? {
        nil
    }

    func flowSection(baseToken _: Token, currency _: Currency, rates _: [String: Decimal]) -> (SendField, SendField)? {
        nil
    }
}

struct SendDataSection {
    let fields: [SendField]
    let isMain: Bool
    let isFlow: Bool
    let isList: Bool

    init(_ fields: [SendField], isMain: Bool = true, isFlow: Bool = false, isList: Bool = true) {
        self.fields = fields
        self.isMain = isMain
        self.isFlow = isFlow
        self.isList = isList
    }

    @ViewBuilder var fieldList: some View {
        ForEach(fields.indices, id: \.self) { index in
            fields[index].listRow
            if isFlow, index < (fields.count - 1) {
                flowDivider
            }
        }
    }

    @ViewBuilder private var flowDivider: some View {
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
    @ViewBuilder var sectionViews: some View {
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
