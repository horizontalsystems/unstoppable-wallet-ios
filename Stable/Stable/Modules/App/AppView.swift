import SwiftUI

struct AppView: View {
    @AppStorage("introShown") private var introShown = false

    var body: some View {
        ZStack {
            ThemeView {
                VStack {
                    ThemeText("Main View", style: .title1)
                    ThemeButton(text: "back to intro") {
                        introShown = false
                    }
                }
                .padding(.horizontal, 24)
            }

            if !introShown {
                IntroView {
                    introShown = true
                }
            }
        }
    }
}
