import UIKit
import ThemeKit
import SnapKit

class InputCell: UITableViewCell {
    private let anInputView: InputView

    init(singleLine: Bool = false) {
        anInputView = InputView(singleLine: singleLine)
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(anInputView)
        anInputView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        anInputView.becomeFirstResponder()
    }

}

extension InputCell {

    var inputPlaceholder: String? {
        get { anInputView.inputPlaceholder }
        set { anInputView.inputPlaceholder = newValue }
    }

    var inputText: String? {
        get { anInputView.inputText }
        set { anInputView.inputText = newValue }
    }

    var font: UIFont? {
        get { anInputView.font }
        set { anInputView.font = newValue }
    }

    var textColor: UIColor? {
        get { anInputView.textColor }
        set { anInputView.textColor = newValue }
    }

    var accessoryEnabled: Bool {
        get { anInputView.accessoryEnabled }
        set { anInputView.accessoryEnabled = newValue }
    }

    var keyboardType: UIKeyboardType {
        get { anInputView.keyboardType }
        set { anInputView.keyboardType = newValue }
    }

    var autocapitalizationType: UITextAutocapitalizationType {
        get { anInputView.autocapitalizationType }
        set { anInputView.autocapitalizationType = newValue }
    }

    func set(cautionType: CautionType?) {
        anInputView.set(cautionType: cautionType)
    }

    var onChangeText: ((String?) -> ())? {
        get { anInputView.onChangeText }
        set { anInputView.onChangeText = newValue }
    }

    var onChangeEditing: ((Bool) -> ())? {
        get { anInputView.onChangeEditing }
        set { anInputView.onChangeEditing = newValue }
    }

    var onChangeHeight: (() -> ())? {
        get { anInputView.onChangeHeight }
        set { anInputView.onChangeHeight = newValue }
    }

    var isValidText: ((String) -> Bool)? {
        get { anInputView.isValidText }
        set { anInputView.isValidText = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        anInputView.height(containerWidth: containerWidth)
    }

}
