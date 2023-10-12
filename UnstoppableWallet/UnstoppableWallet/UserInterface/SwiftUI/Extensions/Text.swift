import SwiftUI

extension Text {
    func themeBody(color: Color = .themeLeah, alignment: Alignment = .leading) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
            .foregroundColor(color)
            .font(.themeBody)
    }

    func themeSubhead1(color: Color = .themeGray, alignment: Alignment = .leading) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
            .foregroundColor(color)
            .font(.themeSubhead1)
    }

    func themeSubhead2(color: Color = .themeGray, alignment: Alignment = .leading) -> some View {
        frame(maxWidth: .infinity, alignment: alignment)
            .foregroundColor(color)
            .font(.themeSubhead2)
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
}
