import UIKit
import SnapKit

class BalanceHeaderView: UIView {
    static let height: CGFloat = .heightSingleLineCell

    private let amountLabel = UILabel()
    private let sortButton = UIButton()

    var onClickSort: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear
        preservesSuperviewLayoutMargins = true

        let wrapperView = UIView()
        wrapperView.backgroundColor = AppTheme.navigationBarBackgroundColor

        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(BalanceHeaderView.height)
        }

        amountLabel.font = .appTitle3
        amountLabel.preservesSuperviewLayoutMargins = true

        wrapperView.addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        sortButton.setImage(UIImage(named: "Balance Sort Icon")?.tinted(with: .appJacob), for: .normal)
        sortButton.addTarget(self, action: #selector(onSortClicked), for: .touchUpInside)

        wrapperView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
            maker.width.equalTo(60)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: BalanceHeaderViewItem) {
        amountLabel.text = ValueFormatter.instance.format(currencyValue: viewItem.currencyValue)
        amountLabel.textColor = viewItem.upToDate ? .appJacob : .appYellow50
    }

    func setSortButton(hidden: Bool) {
        sortButton.isHidden = hidden
    }

    @objc func onSortClicked() {
        onClickSort?()
    }

}
