import SwiftUI

struct AppView: View {
    @AppStorage("introShown") private var introShown = false

    var body: some View {
        ZStack {
            SetupWalletView()

            if !introShown {
                IntroView {
                    introShown = true
                }
            }
        }
    }
}
