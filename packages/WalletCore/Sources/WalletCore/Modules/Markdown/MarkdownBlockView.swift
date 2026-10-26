import Kingfisher
import SwiftUI

struct MarkdownBlockView: View {
    let viewItem: MarkdownBlockViewItem

    var body: some View {
        switch viewItem {
        case let .header(attributedString, level):
            if level == 1 || level == 2 {
                VStack(alignment: .leading, spacing: 0) {
                    ThemeText(attributedString, style: .title2, colorStyle: .primary)
                        .multilineTextAlignment(.leading)

                    HorizontalDivider(color: .themeGray50)
                        .padding(.top, .margin8)
                }
                .padding(.top, .margin24)
                .padding(.horizontal, .margin24)
                .padding(.bottom, .margin12)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ThemeText(attributedString, style: .headline2, colorStyle: .primary)
                    .multilineTextAlignment(.leading)
                    .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin12, trailing: .margin24))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case let .text(attributedString):
            bodyText(attributedString)
                .padding(.vertical, .margin12)
                .padding(.horizontal, .margin24)
                .frame(maxWidth: .infinity, alignment: .leading)
        case let .listItem(attributedString, prefix, tightTop, tightBottom):
            HStack(alignment: .top, spacing: 0) {
                Group {
                    if let prefix {
                        ThemeText(prefix, style: .body)
                    }
                }
                .frame(width: .margin24, alignment: .leading)

                bodyText(attributedString)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, .margin24)
            .padding(.top, tightTop ? .margin4 : .margin12)
            .padding(.bottom, tightBottom ? .margin4 : .margin12)
        case let .blockQuote(attributedString, tightTop, tightBottom):
            ZStack(alignment: .leading) {
                Color.themeBlade

                bodyText(attributedString)
                    .padding(.horizontal, .margin24)
                    .padding(.vertical, .margin12)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Color.themeRemus.frame(width: 4)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, tightTop ? 0 : .margin12)
            .padding(.bottom, tightBottom ? 0 : .margin12)
        case let .image(url, type, tight):
            Color.clear
                .aspectRatio(type.aspectRatio, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay {
                    KFImage.url(url)
                        .resizable()
                        .placeholder { Color.themeBlade }
                        .scaledToFill()
                }
                .clipped()
                .padding(.vertical, tight ? 0 : .margin12)
        case let .imageTitle(text):
            ThemeText(text, style: .subheadR)
                .multilineTextAlignment(.leading)
                .padding(.vertical, .margin12)
                .padding(.horizontal, .margin24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func bodyText(_ attributedString: AttributedString) -> some View {
        ThemeText(attributedString, style: .body, colorStyle: .primary)
            .lineSpacing(6)
            .multilineTextAlignment(.leading)
            .tint(.themeJacob)
    }
}
