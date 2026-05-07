import SwiftUI

struct TabButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .font(.themeSubhead1)
            .foregroundColor(isActive ? .themeLeah : .themeGray)
            .contentShape(Rectangle())
    }
}
