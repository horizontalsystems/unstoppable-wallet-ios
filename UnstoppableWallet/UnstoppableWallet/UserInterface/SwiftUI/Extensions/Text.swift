import SwiftUI
import ThemeKit

extension View {
    func textBody(color: Color = .themeLeah) -> some View {
        foregroundColor(color).font(.themeBody)
    }

    func textSubhead1(color: Color = .themeGray) -> some View {
        foregroundColor(color).font(.themeSubhead1)
    }

    func textSubhead2(color: Color = .themeGray) -> some View {
        foregroundColor(color).font(.themeSubhead2)
    }

    func textCaption(color: Color = .themeGray) -> some View {
        foregroundColor(color).font(.themeCaption)
    }

    func textCaptionSB(color: Color = .themeGray) -> some View {
        foregroundColor(color).font(.themeCaptionSB)
    }

    func textHeadline1(color: Color = .themeLeah) -> some View {
        foregroundColor(color).font(.themeHeadline1)
    }

    func textHeadline2(color: Color = .themeLeah) -> some View {
        foregroundColor(color).font(.themeHeadline2)
    }

    func textMicro(color: Color = .themeGray) -> some View {
        foregroundColor(color).font(.themeMicro)
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
        textCaption(color: color).frame(maxWidth: .infinity, alignment: alignment)
    }

    func themeCaptionSB(color: Color = .themeGray, alignment: Alignment = .leading) -> some View {
        textCaptionSB(color: color).frame(maxWidth: .infinity, alignment: alignment)
    }

    func themeHeadline1(color: Color = .themeLeah, alignment: Alignment = .leading) -> some View {
        textHeadline1(color: color).frame(maxWidth: .infinity, alignment: alignment)
    }

    func themeHeadline2(color: Color = .themeLeah, alignment: Alignment = .leading) -> some View {
        textHeadline2(color: color).frame(maxWidth: .infinity, alignment: alignment)
    }

    func themeMicro(color: Color = .themeGray, alignment: Alignment = .leading) -> some View {
        textMicro(color: color).frame(maxWidth: .infinity, alignment: alignment)
    }
}
