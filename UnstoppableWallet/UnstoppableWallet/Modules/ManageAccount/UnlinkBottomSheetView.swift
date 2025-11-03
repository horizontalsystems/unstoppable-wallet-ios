import SwiftUI

struct UnlinkBottomSheetView: View {
    @StateObject private var selectorViewModel = SelectorGroupsViewModel()
    @StateObject private var buttonViewModel = ButtonGroupViewModel()
    @Binding private var isPresented: Bool

    private let items = [
        "settings_manage_keys.delete.confirmation_remove".localized,
        "settings_manage_keys.delete.confirmation_loose".localized,
    ]

    private let onUnlink: () -> Void

    private enum Controls {
        static let selector = "selector"
        static let delete = "delete"
    }

    init(isPresented: Binding<Bool>, onUnlink: @escaping () -> Void) {
        _isPresented = isPresented
        self.onUnlink = onUnlink
    }

    var body: some View {
        BottomSheetView(views: views())
            .onAppear {
                updateViewModels()
            }
            .onChange(of: selectorViewModel.groupStates[Controls.selector]) { _ in
                updateButtonState()
            }
    }

    private func views() -> [AnyView] {
        var views: [AnyView] = []

        views.append(BSModule.view(for: .title(
            showGrabber: true,
            icon: .trash,
            title: "settings_manage_keys.delete.title".localized,
            isPresented: $isPresented
        )))

        let group = GroupSelector(
            id: Controls.selector,
            items: items.map { .init(id: $0, description: $0) }
        )

        views.append(AnyView(
            SelectorGroupView(group: group, viewModel: selectorViewModel)
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin8)
        ))

        let buttonGroup = ButtonGroupViewModel.ButtonGroup(
            buttons: [
                .init(
                    id: Controls.delete,
                    style: .gray,
                    title: "security_settings.delete_alert_button".localized,
                    action: {
                        onUnlink()
                        isPresented = false
                    }
                ),
            ]
        )
        views.append(AnyView(
            ButtonGroupView(group: buttonGroup, viewModel: buttonViewModel)
        ))

        return views
    }

    private func updateViewModels() {
        selectorViewModel.append(id: Controls.selector, initialSelection: [])
        buttonViewModel.append(id: Controls.delete, isDisabled: true)
    }

    private func updateButtonState() {
        let hasSelection = !(selectorViewModel.getSelection(Controls.selector).isEmpty)
        buttonViewModel.setDisabled(!hasSelection, for: Controls.delete)
    }
}
