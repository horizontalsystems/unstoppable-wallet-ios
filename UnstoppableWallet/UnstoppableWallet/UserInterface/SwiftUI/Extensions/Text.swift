import SwiftUI
import ThemeKit

extension Text {
    func textBody(color: Color = .themeLeah) -> some View {
        foregroundColor(color).font(.themeBody)
    }

    func textSubhead1(color: Color = .themeGray) -> some View {
        foregroundColor(color).font(.themeSubhead1)
    }

    func textSubhead2(color: Color = .themeGray) -> some View {
        foregroundColor(color).font(.themeSubhead2)
    }

    func themeBody(color: Color = .themeLeah, alignment: Alignment = .leading) -> some View {
        textBody(color: color).frame(maxWidth: .infinity, alignment: alignment)
    }

    func themeSubhead1(color: Color = .themeGray, alignment: Alignment = .leading) -> some View {
        textSubhead1(color: color).frame(maxWidth: .infinity, alignment: alignment)
    }

    func themeSubhead2(color: Color = .themeGray, alignment: Alignment = .leading) -> some View {
        textSubhead2(color: color).frame(maxWidth: .infinity, alignment: alignment)
    }

    func themeCaption(color: Color = .themeGray, alignment: Alignment = .leading) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
            .foregroundColor(color)
            .font(.themeCaption)
    }

    func themeCaptionSB(color: Color = .themeGray, alignment: Alignment = .leading) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
            .foregroundColor(color)
            .font(.themeCaptionSB)
    }

    func themeHeadline1(color: Color = .themeLeah, alignment: Alignment = .leading) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
            .foregroundColor(color)
            .font(.themeHeadline1)
    }

    func themeHeadline2(color: Color = .themeLeah, alignment: Alignment = .leading) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
            .foregroundColor(color)
            .font(.themeHeadline2)
    }
}
