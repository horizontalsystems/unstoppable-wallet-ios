import UIKit
import SnapKit

class RestoreHeaderView: UIView {
    private static var text: String {
        return "restore.description".localized
    }

    private let label = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(label)

        label.text = RestoreHeaderView.text
        label.numberOfLines = 0
        label.font = RestoreAccountsTheme.descriptionFont
        label.textColor = RestoreAccountsTheme.descriptionColor
        label.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(RestoreAccountsTheme.descriptionSideMargin)
            maker.trailing.equalToSuperview().offset(-RestoreAccountsTheme.descriptionSideMargin)
            maker.top.equalToSuperview().offset(RestoreAccountsTheme.descriptionTopMargin)
            maker.bottom.equalToSuperview().offset(-RestoreAccountsTheme.descriptionBottomMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}

extension RestoreHeaderView {

    static func height(containerWidth: CGFloat) -> CGFloat {
        return text.height(forContainerWidth: containerWidth - 2 * RestoreAccountsTheme.descriptionSideMargin, font: RestoreAccountsTheme.descriptionFont) + RestoreAccountsTheme.descriptionTopMargin + RestoreAccountsTheme.descriptionBottomMargin
    }

}
