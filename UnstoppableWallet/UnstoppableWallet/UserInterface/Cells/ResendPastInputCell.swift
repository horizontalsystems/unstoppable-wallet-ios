import SnapKit

import UIKit

class ResendPasteInputCell: UITableViewCell {
    private let view = ResendPasteInputView()

    init() {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(view)
        view.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ResendPasteInputCell {
    var inputPlaceholder: String? {
        get { view.inputPlaceholder }
        set { view.inputPlaceholder = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { view.keyboardType }
        set { view.keyboardType = newValue }
    }

    var inputText: String? {
        get { view.inputText }
        set { view.inputText = newValue }
    }

    var isEditable: Bool {
        get { view.isEditable }
        set { view.isEditable = newValue }
    }

    var isEnabled: Bool {
        get { view.isEnabled }
        set { view.isEnabled = newValue }
    }

    var isResendEnabled: Bool {
        get { view.resendView.button.isEnabled }
        set { view.resendView.button.isEnabled = newValue }
    }

    func set(cautionType: CautionType?) {
        view.set(cautionType: cautionType)
    }

    var onChangeText: ((String?) -> Void)? {
        get { view.onChangeText }
        set { view.onChangeText = newValue }
    }

    var onFetchText: ((String?) -> Void)? {
        get { view.onFetchText }
        set { view.onFetchText = newValue }
    }

    var onResend: (() -> Void)? {
        get { view.onResend }
        set { view.onResend = newValue }
    }

    var onChangeEditing: ((Bool) -> Void)? {
        get { view.onChangeEditing }
        set { view.onChangeEditing = newValue }
    }

    var onChangeHeight: (() -> Void)? {
        get { view.onChangeHeight }
        set { view.onChangeHeight = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        view.height(containerWidth: containerWidth)
    }
}
