import SwiftUI

struct WelcomeLogoView: View {
    private static let size: CGFloat = 96

    var body: some View {
        ThemeImage("uw_logo_filled", size: Self.size, colorStyle: .brand)
    }
}
