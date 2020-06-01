import UIKit
import ThemeKit

class AddressInputFieldCell: UITableViewCell {
    private static let inputFieldHeight: CGFloat = .heightSingleLineCell // todo: make AddressInputField height dynamic and get height from it
    private static let verticalPadding: CGFloat = .margin3x

    private let inputField = AddressInputField()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        addSubview(inputField)
        inputField.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview().inset(AddressInputFieldCell.verticalPadding)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(placeholder: String? = nil, canEdit: Bool = true, lineBreakMode: NSLineBreakMode = .byWordWrapping, address: String?, error: Error? = nil, onPaste: (() -> ())?, onDelete: (() -> ())?) {
        inputField.placeholder = placeholder
        inputField.canEdit = canEdit
        inputField.lineBreakMode = lineBreakMode

        inputField.bind(address: address, error: error)

        inputField.onPaste = onPaste
        inputField.onDelete = onDelete
    }

}

extension AddressInputFieldCell {

    static func height(containerWidth: CGFloat, address: String?, error: Error?) -> CGFloat {
        inputFieldHeight + 2 * verticalPadding
    }

}
