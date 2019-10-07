import UIKit
import SnapKit

class DescriptionView: UIView {
    private static let sideMargin: CGFloat = .margin6x
    private static let topMargin: CGFloat = .margin3x
    private static let bottomMargin: CGFloat = .margin6x
    private static let font: UIFont = .appSubhead2

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.numberOfLines = 0
        label.font = DescriptionView.font
        label.textColor = .cryptoGray

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(DescriptionView.sideMargin)
            maker.top.equalToSuperview().offset(DescriptionView.topMargin)
            maker.bottom.equalToSuperview().inset(DescriptionView.bottomMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        label.text = text
    }

}

extension DescriptionView {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * DescriptionView.sideMargin, font: DescriptionView.font)
        return textHeight + DescriptionView.topMargin + DescriptionView.bottomMargin
    }

}
