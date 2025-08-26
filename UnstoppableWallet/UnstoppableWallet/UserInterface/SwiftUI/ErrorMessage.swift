import SwiftUI

struct ErrorMessage<Content: View>: View {
    let icon: String
    var title: String?
    var subtitle: String?
    @ViewBuilder var additionalContent: Content

    var body: some View {
        VStack(spacing: .margin24) {
            VStack(spacing: .margin16) {
                ZStack {
                    Image(icon).icon(size: .iconSize72)
                }
                .padding(.margin16)

                VStack(spacing: .margin8) {
                    if let title {
                        ThemeText(title, style: .headline2)
                            .multilineTextAlignment(.center)
                    }

                    if let subtitle {
                        ThemeText(subtitle, style: .subheadR)
                            .multilineTextAlignment(.center)
                    }
                }
            }

            additionalContent
        }
        .frame(width: 264)
    }
}

extension ErrorMessage where Content == EmptyView {
    init(icon: String, title: String? = nil, subtitle: String? = nil) {
        self.init(icon: icon, title: title, subtitle: subtitle, additionalContent: { EmptyView() })
    }
}
