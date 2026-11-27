import SwiftUI

/// The logo at the centre of the full screen. `effects` is applied to the logo image itself, before the centring,
/// so scale and other transforms are anchored at the logo's own centre.
struct WelcomeLogoView<Logo: View>: View {
    private static var size: CGFloat {
        96
    }

    private let logo: Logo

    init(@ViewBuilder effects: (ThemeImage) -> Logo) {
        logo = effects(ThemeImage("uw_logo_filled", size: Self.size, colorStyle: .brand))
    }

    var body: some View {
        logo
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}

extension WelcomeLogoView where Logo == ThemeImage {
    init() {
        self.init { $0 }
    }
}
