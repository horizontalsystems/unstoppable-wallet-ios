import SnapKit
import ThemeKit
import UIKit

class PasteInputCell: UITableViewCell {
    private let pasteInputView = PasteInputView()

    init() {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(pasteInputView)
        pasteInputView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PasteInputCell {
    var inputPlaceholder: String? {
        get { pasteInputView.inputPlaceholder }
        set { pasteInputView.inputPlaceholder = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { pasteInputView.keyboardType }
        set { pasteInputView.keyboardType = newValue }
    }

    var inputText: String? {
        get { pasteInputView.inputText }
        set { pasteInputView.inputText = newValue }
    }

    var isEditable: Bool {
        get { pasteInputView.isEditable }
        set { pasteInputView.isEditable = newValue }
    }

    var isEnabled: Bool {
        get { pasteInputView.isEnabled }
        set { pasteInputView.isEnabled = newValue }
    }

    func set(cautionType: CautionType?) {
        pasteInputView.set(cautionType: cautionType)
    }

    var onChangeText: ((String?) -> Void)? {
        get { pasteInputView.onChangeText }
        set { pasteInputView.onChangeText = newValue }
    }

    var onFetchText: ((String?) -> Void)? {
        get { pasteInputView.onFetchText }
        set { pasteInputView.onFetchText = newValue }
    }

    var onChangeEditing: ((Bool) -> Void)? {
        get { pasteInputView.onChangeEditing }
        set { pasteInputView.onChangeEditing = newValue }
    }

    var onChangeHeight: (() -> Void)? {
        get { pasteInputView.onChangeHeight }
        set { pasteInputView.onChangeHeight = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        pasteInputView.height(containerWidth: containerWidth)
    }
}
