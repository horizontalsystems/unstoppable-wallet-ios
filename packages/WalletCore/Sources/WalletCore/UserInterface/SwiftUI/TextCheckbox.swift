import SwiftUI

public struct TextCheckbox: View {
    var title: CustomStringConvertible?
    var subhead: CustomStringConvertible?
    var subheadSB: CustomStringConvertible?
    var description: CustomStringConvertible?
    var description2: CustomStringConvertible?
    let checked: Bool
    var alignment: HorizontalAlignment = .trailing

    public init(
        title: CustomStringConvertible? = nil,
        subhead: CustomStringConvertible? = nil,
        subheadSB: CustomStringConvertible? = nil,
        description: CustomStringConvertible? = nil,
        description2: CustomStringConvertible? = nil,
        checked: Bool,
        alignment: HorizontalAlignment = .trailing
    ) {
        self.title = title
        self.subhead = subhead
        self.subheadSB = subheadSB
        self.description = description
        self.description2 = description2
        self.checked = checked
        self.alignment = alignment
    }

    public var body: some View {
        HStack(spacing: 12) {
            let leading = alignment == .leading
            let textAligment: TextAlignment = leading ? .leading : .trailing

            if leading {
                Image.checkbox(active: checked, size: 20)
            }

            VStack(alignment: alignment, spacing: 0) {
                if let title {
                    ThemeText(title, style: .headline2)
                        .multilineTextAlignment(textAligment)
                }

                if let subhead {
                    ThemeText(subhead, style: .subhead)
                        .multilineTextAlignment(textAligment)
                }

                if let subheadSB {
                    ThemeText(subheadSB, style: .subheadSB)
                        .multilineTextAlignment(textAligment)
                }

                if description != nil || description2 != nil {
                    HStack(spacing: 4) {
                        if let description {
                            ThemeText(description, style: .subhead)
                                .multilineTextAlignment(textAligment)
                        }

                        if let description2 {
                            ThemeText(description2, style: .subhead)
                                .multilineTextAlignment(textAligment)
                        }
                    }
                }
            }

            if alignment != .leading {
                Image.checkbox(active: checked, size: 20)
            }
        }
    }
}
