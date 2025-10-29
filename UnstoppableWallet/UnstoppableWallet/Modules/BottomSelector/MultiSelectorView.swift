import SwiftUI

struct BottomMultiSelectorView: View {
    let config: SelectorModule.MultiConfig
    let delegate: IBottomMultiSelectorDelegate

    @Binding var isPresented: Bool
    @StateObject private var selectorViewModel: SelectorGroupsViewModel
    @StateObject private var buttonViewModel: ButtonGroupViewModel

    init(
        config: SelectorModule.MultiConfig,
        delegate: IBottomMultiSelectorDelegate,
        isPresented: Binding<Bool>
    ) {
        self.config = config
        self.delegate = delegate
        _isPresented = isPresented

        let selectorViewModel = SelectorGroupsViewModel()
        let buttonViewModel = ButtonGroupViewModel()

        let selectedIndices = config.viewItems.enumerated()
            .filter(\.element.selected)
            .map { "\($0.offset)" }

        selectorViewModel.append(
            id: Controls.selector,
            initialSelection: Set(selectedIndices)
        )

        buttonViewModel.append(id: Controls.apply, isDisabled: !config.allowEmpty && selectedIndices.isEmpty)

        _selectorViewModel = StateObject(wrappedValue: selectorViewModel)
        _buttonViewModel = StateObject(wrappedValue: buttonViewModel)
    }

    var body: some View {
        BottomSheetView(
            title: config.title,
            items: items,
            isPresented: $isPresented,
            selectorViewModel: selectorViewModel,
            buttonViewModel: buttonViewModel
        )
        .onChange(of: selectorViewModel.groupStates[Controls.selector]) { _ in
            updateButtonState()
        }
    }

    private var items: [BottomSheetView.Item] {
        var items = [BottomSheetView.Item]()
        if let description = config.description {
            items.append(.text(text: description))
        }

        items.append(contentsOf: [
            .groupSelector(
                GroupSelector(
                    id: Controls.selector,
                    items: config.viewItems.enumerated().map { index, viewItem in
                        GroupSelectorItem(
                            id: "\(index)",
                            text: viewItem.title,
                            description: viewItem.subtitle
                        )
                    },
                    type: .multi,
                    style: .switcher,
                    requireSelection: !config.allowEmpty
                )
            ),
        ])

        if let footer = config.footer {
            items.append(.footer(text: footer))
        }

        items.append(contentsOf: [
            .buttonGroup(
                ButtonGroupViewModel.ButtonGroup(
                    buttons: [
                        ButtonGroupViewModel.ButtonItem(
                            id: Controls.apply,
                            style: .yellow,
                            title: "button.done".localized,
                            action: handleApply
                        ),
                    ],
                    alignment: .vertical
                )
            ),
        ])

        return items
    }

    private func updateButtonState() {
        let selection = selectorViewModel.getSelection(Controls.selector)

        if !config.allowEmpty {
            buttonViewModel.setDisabled(selection.isEmpty, for: Controls.apply)
        }
    }

    private func handleApply() {
        let selection = selectorViewModel.getSelection(Controls.selector)
        let indices = selection.compactMap { Int($0) }.sorted()

        delegate.bottomSelectorOnSelect(indexes: indices)
        isPresented = false
    }

    private enum Controls {
        static let selector = "selector"
        static let apply = "apply"
    }
}

extension SelectorModule {
    static func bottomMultiSelectorView(
        config: MultiConfig,
        delegate: IBottomMultiSelectorDelegate,
        isPresented: Binding<Bool>
    ) -> some View {
        BottomMultiSelectorView(
            config: config,
            delegate: delegate,
            isPresented: isPresented
        )
    }

    static func bottomMultiSelectorViewController(
        config: MultiConfig,
        delegate: IBottomMultiSelectorDelegate
    ) -> UIViewController {
        let wrapper = BottomMultiSelectorHostingController(
            config: config,
            delegate: delegate
        )
        return wrapper.toBottomSheet
    }

    private class BottomMultiSelectorHostingController: UIHostingController<BottomMultiSelectorView> {
        init(config: SelectorModule.MultiConfig, delegate: IBottomMultiSelectorDelegate) {
            // stubbing view for Hosting creation.
            let stubIsPresented = Binding<Bool>(get: { true }, set: { _ in })
            let stubView = BottomMultiSelectorView(config: config, delegate: delegate, isPresented: stubIsPresented)
            super.init(rootView: stubView)

            // update to view with dismissing
            let isPresented = Binding<Bool>(
                get: { true },
                set: { [weak self] newValue in
                    if !newValue {
                        self?.dismiss(animated: true)
                    }
                }
            )

            let view = BottomMultiSelectorView(
                config: config,
                delegate: delegate,
                isPresented: isPresented
            )

            rootView = view
        }

        @available(*, unavailable)
        @MainActor dynamic required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
