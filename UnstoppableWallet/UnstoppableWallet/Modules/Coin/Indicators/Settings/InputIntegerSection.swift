import UIKit
import SectionsTableView

class InputIntegerSection {
    private let inputCell = ShortcutInputCell()
    private let inputCautionCell = FormCautionCell()

    let id: String

    var onChangeText: ((String?) -> ())?
    var onReload: (() -> ())?

    init(id: String, placeholder: String?, initialValue: String?) {
        self.id = id

        inputCell.inputPlaceholder = placeholder
        inputCell.inputText = initialValue
        inputCell.keyboardType = .decimalPad

        inputCell.isValidText = { [weak self] text in self?.isValid(text: text) ?? true }
        inputCell.onChangeText = { [weak self] text in self?.onChangeText?(text) }

        inputCautionCell.onChangeHeight = { [weak self] in self?.onReload?() }
    }

    private func isValid(text: String) -> Bool {
        guard let intValue = Int(text), intValue > 0 else {
            return false
        }
        return true
    }

}

extension InputIntegerSection {

    func set(caution: Caution?) {
        inputCautionCell.set(caution: caution)
    }

    var text: String? {
        get { inputCell.inputText }
        set { inputCell.inputText = newValue }
    }

    func section(tableView: SectionsTableView, header: String?) -> SectionProtocol {
        Section(id: id,
                headerState: header.map { tableView.sectionHeader(text: $0) } ?? .margin(height: 0),
                footerState: .margin(height: .margin24),
                rows: [
                    StaticRow(
                            cell: inputCell,
                            id: id + "_input",
                            dynamicHeight: { [weak self] width in
                                self?.inputCell.height(containerWidth: width) ?? 0
                            }
                    ),
                    StaticRow(
                            cell: inputCautionCell,
                            id: id + "_caution",
                            dynamicHeight: { [weak self] width in
                                self?.inputCautionCell.height(containerWidth: width) ?? 0
                            }
                    )
                ]
        )
    }
}
