import SwiftUI

struct CoverView: View {
    var body: some View {
        ZStack {
            WelcomeGlowView(start: nil)

            WelcomeLogoView()
        }
    }
}
