import SwiftUI

struct MultiText: View {
    var eyebrow: CustomStringConvertible?
    let title: CustomStringConvertible?
    var badge: CustomStringConvertible?
    var subtitleBadge: CustomStringConvertible?
    var subtitle: CustomStringConvertible?
    var subtitle2: CustomStringConvertible?
    var description: CustomStringConvertible?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let eyebrow {
                ThemeText(eyebrow, style: .subhead)
                    .multilineTextAlignment(.leading)
            }

            HStack(spacing: .margin8) {
                if let title {
                    ThemeText(title, style: .headline2)
                        .multilineTextAlignment(.leading)
                }

                if let badge {
                    BadgeViewNew(badge)
                }
            }

            HStack(spacing: .margin8) {
                if let subtitleBadge {
                    BadgeViewNew(subtitleBadge)
                }

                HStack(spacing: .margin4) {
                    if let subtitle {
                        ThemeText(subtitle, style: .subhead)
                            .multilineTextAlignment(.leading)
                    }

                    if let subtitle2 {
                        ThemeText(subtitle2, style: .subhead)
                            .multilineTextAlignment(.leading)
                    }
                }
            }

            if let description {
                ThemeText(description, style: .captionSB)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}
