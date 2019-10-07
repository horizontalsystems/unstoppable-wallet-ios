import UIKit
import SnapKit

class BottomDescriptionView: UIView {
    private static let sideMargin: CGFloat = .margin6x
    private static let topMargin: CGFloat = .margin2x
    private static let bottomMargin: CGFloat = .margin12x
    private static let font: UIFont = .appSubhead2

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.numberOfLines = 0
        label.font = BottomDescriptionView.font
        label.textColor = .cryptoGray

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(BottomDescriptionView.sideMargin)
            maker.top.equalToSuperview().offset(BottomDescriptionView.topMargin)
            maker.bottom.equalToSuperview().inset(BottomDescriptionView.bottomMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        label.text = text
    }

}

extension BottomDescriptionView {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * BottomDescriptionView.sideMargin, font: BottomDescriptionView.font)
        return textHeight + BottomDescriptionView.topMargin + BottomDescriptionView.bottomMargin
    }

}
