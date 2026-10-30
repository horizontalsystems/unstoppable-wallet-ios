import SwiftUI

struct StepChangeButtonsView<Content: View>: View {
    @ViewBuilder let content: Content
    let onTap: (StepChangeButtonsViewDirection) -> Void

    var body: some View {
        PrimarySizedHStack {
            content
        } trailing: {
            HStack(spacing: .margin16) {
                IconButton(icon: "minus", style: .secondary, size: .small) {
                    onTap(.down)
                }

                IconButton(icon: "plus", style: .secondary, size: .small) {
                    onTap(.up)
                }
            }
        }
    }
}

enum StepChangeButtonsViewDirection {
    case down, up
}
