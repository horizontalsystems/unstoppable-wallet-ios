import Foundation
import SwiftUI

struct DiffText: View {
    private let diff: Diff?
    private let font: Font
    private let expired: Bool

    init(_ diff: Diff?, font: Font = .themeSubhead2, expired: Bool = false) {
        self.diff = diff
        self.font = font
        self.expired = expired
    }

    init(_ diff: Decimal?, font: Font = .themeSubhead2, expired: Bool = false) {
        self.diff = diff.map { .percent(value: $0) }
        self.font = font
        self.expired = expired
    }

    init(_ change: Decimal?, currency: Currency, font: Font = .themeSubhead2, expired: Bool = false) {
        diff = change.map { .change(value: $0, currency: currency) }
        self.font = font
        self.expired = expired
    }

    var body: some View {
        if let (text, value) = resolved {
            Text(text)
                .foregroundColor(expired ? .themeGray50 : (value == 0 ? .themeGray : (value.isSignMinus ? .themeLucian : .themeRemus)))
                .font(font)
                .lineLimit(1)
                .truncationMode(.middle)
        } else {
            Text("----")
                .foregroundColor(.themeGray)
                .font(font)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var resolved: (String, Decimal)? {
        guard let diff else {
            return nil
        }

        switch diff {
        case let .percent(value): return ValueFormatter.instance.format(percentValue: value).map { ($0, value) }
        case let .change(value, currency): return ValueFormatter.instance.formatShort(currency: currency, value: value, signType: .always).map { ($0, value) }
        }
    }
}

extension DiffText {
    enum Diff {
        case percent(value: Decimal)
        case change(value: Decimal, currency: Currency)
    }
}
