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
        .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin16, trailing: .margin24))
    }

    @ViewBuilder
    private var buttonViews: some View {
        ForEach(group.buttons) { button in
            buttonView(for: button)
        }
    }

    private func buttonView(for button: ButtonGroupViewModel.ButtonItem) -> some View {
        let isDisabled = viewModel.isDisabled(button.id)

        return ThemeButton(text: button.title, icon: button.icon, style: button.style, mode: button.mode) {
            if !isDisabled {
                button.action()
            }
        }
        .disabled(isDisabled)
    }
}
