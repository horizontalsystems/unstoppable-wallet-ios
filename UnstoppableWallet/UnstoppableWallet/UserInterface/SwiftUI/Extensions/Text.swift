import SwiftUI

extension Text {

    func themeBody(color: Color = .themeLeah, alignment: Alignment = .leading) -> some View {
        self
                .frame(maxWidth: .infinity, alignment: alignment)
                .foregroundColor(color)
                .font(.themeBody)
    }

    func themeSubhead1(color: Color = .themeGray, alignment: Alignment = .leading) -> some View {
        self
                .frame(maxWidth: .infinity, alignment: alignment)
                .foregroundColor(color)
                .font(.themeSubhead1)
    }

    func themeSubhead2(color: Color = .themeGray, alignment: Alignment = .leading) -> some View {
        self
                .frame(maxWidth: .infinity, alignment: alignment)
                .foregroundColor(color)
                .font(.themeSubhead2)
    }

}
