import SwiftUI

struct RightMultiText: View {
    var eyebrow: CustomStringConvertible?
    var title: CustomStringConvertible?
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

            if let subtitle {
                ThemeText(subtitle, style: .subhead)
                    .multilineTextAlignment(.trailing)
            }

            if let description {
                ThemeText(description, style: .captionSB)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
