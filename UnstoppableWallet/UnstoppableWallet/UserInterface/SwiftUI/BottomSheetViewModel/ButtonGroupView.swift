import SwiftUI

struct ButtonGroupView: View {
    let group: ButtonGroupViewModel.ButtonGroup
    @StateObject var viewModel: ButtonGroupViewModel

    init(group: ButtonGroupViewModel.ButtonGroup, viewModel: ButtonGroupViewModel? = nil) {
        self.group = group

        if let viewModel {
            _viewModel = StateObject(wrappedValue: viewModel)
        } else {
            let viewModel = ButtonGroupViewModel()
            for button in group.buttons {
                viewModel.append(id: button.id, isDisabled: false)
            }
            _viewModel = StateObject(wrappedValue: viewModel)
        }
    }

    var body: some View {
        Group {
            switch group.alignment {
            case .vertical:
                VStack(spacing: .margin12) {
                    buttonViews
                }
            case .horizontal:
                HStack(spacing: .margin12) {
                    buttonViews
                }
            }
        }
    }

    @ViewBuilder
    private var buttonViews: some View {
        ForEach(group.buttons) { button in
            buttonView(for: button)
        }
    }

    private func buttonView(for button: ButtonGroupViewModel.ButtonItem) -> some View {
        let isDisabled = viewModel.isDisabled(button.id)

        return Button(
            action: {
                if !isDisabled {
                    button.action()
                }
            },
            label: {
                HStack(spacing: .margin8) {
                    if let icon = button.icon {
                        Image(icon)
                            .renderingMode(.template)
                    }
                    Text(button.title)
                }
            }
        )
        .buttonStyle(PrimaryButtonStyle(style: button.style))
        .disabled(isDisabled)
    }
}
