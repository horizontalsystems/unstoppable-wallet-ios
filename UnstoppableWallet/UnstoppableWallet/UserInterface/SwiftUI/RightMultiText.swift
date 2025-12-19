import SwiftUI

struct RightMultiText: View {
    var eyebrow: CustomStringConvertible?
    var title: CustomStringConvertible?
    var subtitleSB: CustomStringConvertible?
    var subtitle: CustomStringConvertible?
    var description: CustomStringConvertible?

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            if let eyebrow {
                ThemeText(eyebrow, style: .subhead)
                    .multilineTextAlignment(.trailing)
            }

            if let title {
                ThemeText(title, style: .headline2)
                    .multilineTextAlignment(.trailing)
            }

            if subtitleSB != nil || subtitle != nil {
                HStack(spacing: 4) {
                    if let subtitleSB {
                        ThemeText(subtitleSB, style: .subheadSB)
                            .multilineTextAlignment(.trailing)
                    }

                    if let subtitle {
                        ThemeText(subtitle, style: .subhead)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            if let description {
                ThemeText(description, style: .captionSB)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
