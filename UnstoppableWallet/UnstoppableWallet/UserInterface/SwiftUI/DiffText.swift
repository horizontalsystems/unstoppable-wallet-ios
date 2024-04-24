import Foundation
import SwiftUI
import ThemeKit

struct DiffText: View {
    private let value: Decimal?
    private let font: Font

    init(_ value: Decimal?, font: Font = .themeSubhead2) {
        self.value = value
        self.font = font
    }

    var body: some View {
        Text(value.flatMap { ValueFormatter.instance.format(percentValue: $0) } ?? "----")
            .foregroundColor(value.map { $0.isSignMinus ? .themeLucian : .themeRemus } ?? .themeGray)
            .font(font)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}
