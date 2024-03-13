import SwiftUI

struct StepChangeButtonsView<Content: View>: View {
    @ViewBuilder let content: Content
    let onTap: (StepChangeButtonsViewDirection) -> Void

    var body: some View {
        HStack(spacing: .margin16) {
            content

            Button(action: {
                onTap(.down)
            }, label: {
                Image("minus_20").renderingMode(.template)
            })
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))

            Button(action: {
                onTap(.up)
            }, label: {
                Image("plus_20").renderingMode(.template)
            })
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))
        }
    }
}

enum StepChangeButtonsViewDirection {
    case down, up
}
