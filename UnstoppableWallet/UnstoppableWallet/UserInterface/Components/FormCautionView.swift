import UIKit
import ThemeKit
import SnapKit

class FormCautionView: UIView {
    private let padding = UIEdgeInsets(top: .margin8, left: .margin32, bottom: 0, right: .margin32)
    private let font: UIFont = .caption

    private let label = UILabel()

    var onChangeHeight: (() -> ())?

    init() {
        super.init(frame: .zero)

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview().inset(padding)
        }

        label.numberOfLines = 0
        label.font = font
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension FormCautionView {

    func set(caution: Caution?) {
        if let caution = caution {
            label.text = caution.text
            label.textColor = caution.type.labelColor
        } else {
            label.text = nil
        }

        onChangeHeight?()
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        guard let text = label.text, !text.isEmpty else {
            return 0
        }

        let textWidth = containerWidth - padding.width
        let textHeight = text.height(forContainerWidth: textWidth, font: font)

        return textHeight + padding.height
    }

}
