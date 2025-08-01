
import SnapKit

import UIKit

class WalletTokenCell: BaseSelectableThemeCell {
    static let height = BalanceTopView.height

    private let topView = BalanceTopView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(topView)
        topView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: BalanceViewItem, animated: Bool = false, duration: TimeInterval = 0.2, onTapError: (() -> Void)?) {
        topView.bind(viewItem: viewItem.topViewItem, onTapError: onTapError)
        topView.layoutIfNeeded()

        if animated {
            UIView.animate(withDuration: duration) {
                self.contentView.layoutIfNeeded()
            }
        }
    }
}
