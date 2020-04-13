import ActionSheet

class DerivationAlertItem: BaseActionItem {
    let derivation: MnemonicDerivation
    var selected: Bool

    init(derivation: MnemonicDerivation, selected: Bool, tag: Int, onSelect: @escaping () -> ()) {
        self.derivation = derivation
        self.selected = selected

        super.init(cellType: DerivationAlertItemView.self, tag: tag, required: true) { _ in
            onSelect()
        }

        height = .heightDoubleLineCell
    }

}
