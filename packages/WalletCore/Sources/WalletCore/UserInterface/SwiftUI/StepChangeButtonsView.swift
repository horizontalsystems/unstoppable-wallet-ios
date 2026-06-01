import SwiftUI

struct StepChangeButtonsView<Content: View>: View {
    @ViewBuilder let content: Content
    let onTap: (StepChangeButtonsViewDirection) -> Void

    var body: some View {
        PrimarySizedHStack {
            content
        } trailing: {
            HStack(spacing: .margin16) {
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
}

enum StepChangeButtonsViewDirection {
    case down, up
}
