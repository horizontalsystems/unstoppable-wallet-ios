import UIKit
import ThemeKit

class InputFieldCell: UITableViewCell {
    private static let horizontalPadding: CGFloat = .margin4x
    private static let verticalPadding: CGFloat = .margin3x

    private let inputField = InputField()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        addSubview(inputField)
        inputField.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(InputFieldCell.horizontalPadding)
            maker.top.equalToSuperview().inset(InputFieldCell.verticalPadding)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(placeholder: String? = nil, canEdit: Bool = true, text: String?, error: Error? = nil, onPaste: (() -> ())?, onDelete: (() -> ())?) {
        inputField.placeholder = placeholder
        inputField.canEdit = canEdit

        inputField.bind(text: text, error: error)

        inputField.onPaste = onPaste
        inputField.onDelete = onDelete
    }

}

extension InputFieldCell {

    static func height(containerWidth: CGFloat, error: Error?) -> CGFloat {
        InputField.height(error: error, containerWidth: containerWidth - InputFieldCell.horizontalPadding * 2) + 2 * verticalPadding
    }

}
