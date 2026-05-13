import SwiftUI

struct IntroView: View {
    var onFinish: () -> Void

    var body: some View {
        ThemeView {
            VStack {
                Spacer()

                ThemeButton(text: "intro.get_started") {
                    onFinish()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}
