import UIKit
import ThemeKit
import SnapKit

class AddressInputCell: UITableViewCell {
    private let addressInputView = AddressInputView()

    init() {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(addressInputView)
        addressInputView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension AddressInputCell {

    var inputPlaceholder: String? {
        get { addressInputView.inputPlaceholder }
        set { addressInputView.inputPlaceholder = newValue }
    }

    var inputText: String? {
        get { addressInputView.inputText }
        set { addressInputView.inputText = newValue }
    }

    var isEditable: Bool {
        get { addressInputView.isEditable }
        set { addressInputView.isEditable = newValue }
    }

    func set(cautionType: CautionType?) {
        addressInputView.set(cautionType: cautionType)
    }

    func set(isSuccess: Bool) {
        addressInputView.set(isSuccess: isSuccess)
    }

    func set(isLoading: Bool) {
        addressInputView.set(isLoading: isLoading)
    }

    var onChangeText: ((String?) -> ())? {
        get { addressInputView.onChangeText }
        set { addressInputView.onChangeText = newValue }
    }

    var onFetchText: ((String?) -> ())? {
        get { addressInputView.onFetchText }
        set { addressInputView.onFetchText = newValue }
    }

    var onChangeEditing: ((Bool) -> ())? {
        get { addressInputView.onChangeEditing }
        set { addressInputView.onChangeEditing = newValue }
    }

    var onOpenViewController: ((UIViewController) -> ())? {
        get { addressInputView.onOpenViewController }
        set { addressInputView.onOpenViewController = newValue }
    }

    var onChangeHeight: (() -> ())? {
        get { addressInputView.onChangeHeight }
        set { addressInputView.onChangeHeight = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        addressInputView.height(containerWidth: containerWidth)
    }

}
