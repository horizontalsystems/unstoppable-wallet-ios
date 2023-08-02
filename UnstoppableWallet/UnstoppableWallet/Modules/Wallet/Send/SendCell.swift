import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class SendCell: UITableViewCell {
    private let topView = BalanceTopView()
    private let separatorView = UIView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(topView)
        topView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(BalanceTopView.height)
        }

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(topView.snp.bottom)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel20
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: SendViewItem, animated: Bool = false, duration: TimeInterval = 0.2, onTap: (() -> ())? = nil, onTapError: (() -> ())?) {
        topView.bind(viewItem: viewItem.topViewItem, onTapError: onTapError)
        topView.layoutIfNeeded()

        if animated {
            UIView.animate(withDuration: duration) {
                self.contentView.layoutIfNeeded()
            }
        }
    }

    static var height: CGFloat {
        BalanceTopView.height
    }

}
