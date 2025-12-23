import SwiftUI

struct RightTextCheckbox: View {
    var title: CustomStringConvertible?
    var subhead: CustomStringConvertible?
    var subheadSB: CustomStringConvertible?
    var description: CustomStringConvertible?
    var description2: CustomStringConvertible?
    let checked: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 0) {
                if let title {
                    ThemeText(title, style: .headline2)
                        .multilineTextAlignment(.trailing)
                }

                if let subhead {
                    ThemeText(subhead, style: .subhead)
                        .multilineTextAlignment(.trailing)
                }

                if let subheadSB {
                    ThemeText(subheadSB, style: .subheadSB)
                        .multilineTextAlignment(.trailing)
                }

                if description != nil || description2 != nil {
                    HStack(spacing: 4) {
                        if let description {
                            ThemeText(description, style: .captionSB)
                                .multilineTextAlignment(.trailing)
                        }

                        if let description2 {
                            ThemeText(description2, style: .captionSB)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }

            if checked {
                ThemeImage("checkbox_circle_on", size: 20, colorStyle: .yellow)
            } else {
                Circle()
                    .strokeBorder(Color.themeAndy, lineWidth: 1)
                    .frame(size: 20)
            }
        }
    }
}
