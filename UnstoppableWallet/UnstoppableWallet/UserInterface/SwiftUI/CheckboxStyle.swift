import SwiftUI
import ThemeKit

struct CheckboxStyle: ToggleStyle {
    private let size: CGFloat = .margin24 - .heightOneDp

    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            Image("check_2_20")
                .themeIcon(color: .themeJacob)
                .opacity(configuration.isOn ? 1 : 0)
                .frame(width: size, height: size, alignment: .center)
        })
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous)
                .stroke(Color.themeGray, lineWidth: .heightOneDp + .heightOnePixel)
        )

        configuration.label
    }
}
