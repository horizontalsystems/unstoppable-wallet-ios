import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class WalletTokenCell: UITableViewCell {
    private let topSeparatorView = UIView()
    private let topView = BalanceTopView()
    private let separatorView = UIView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(topSeparatorView)
        topSeparatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        topSeparatorView.backgroundColor = .themeSteel20
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

    func bind(viewItem: BalanceViewItem, first: Bool = false, animated: Bool = false, duration: TimeInterval = 0.2, onTapError: (() -> ())?) {
        topSeparatorView.isHidden = !first
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
