import Foundation
import SwiftUI
import ThemeKit

struct DiffText: View {
    private let diff: Diff?
    private let font: Font

    init(_ diff: Diff?, font: Font = .themeSubhead2) {
        self.diff = diff
        self.font = font
    }

    init(_ diff: Decimal?, font: Font = .themeSubhead2) {
        self.diff = diff.map { .percent(value: $0) }
        self.font = font
    }

    init(_ change: Decimal?, currency: Currency, font: Font = .themeSubhead2) {
        diff = change.map { .change(value: $0, currency: currency) }
        self.font = font
    }

    var body: some View {
        if let (text, value) = resolved {
            Text(text)
                .foregroundColor(value == 0 ? .themeGray : (value.isSignMinus ? .themeLucian : .themeRemus))
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
        case let .change(value, currency): return ValueFormatter.instance.formatShort(currency: currency, value: value, showSign: true).map { ($0, value) }
        }
    }
}

extension DiffText {
    enum Diff {
        case percent(value: Decimal)
        case change(value: Decimal, currency: Currency)
    }
}
