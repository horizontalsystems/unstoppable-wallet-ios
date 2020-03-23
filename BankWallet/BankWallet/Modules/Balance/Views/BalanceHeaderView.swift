import UIKit
import SnapKit

class BalanceHeaderView: UICollectionReusableView {
    static let height: CGFloat = 40

    private let amountLabel = UILabel()
    private let hideButton = UIButton()
    private let sortButton = UIButton()

    var onTapSortType: (() -> ())?
    var onTapHide: (() -> ())?

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        tintColor = .clear
        preservesSuperviewLayoutMargins = true
        backgroundColor = .themeNavigationBarBackground

        addSubview(amountLabel)
        amountLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview()
            maker.height.equalTo(BalanceHeaderView.height)
        }

        amountLabel.font = .title3
        amountLabel.preservesSuperviewLayoutMargins = true

        addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.top.trailing.equalToSuperview()
            maker.width.equalTo(60)
            maker.height.equalTo(BalanceHeaderView.height)
        }

        sortButton.setImage(UIImage(named: "Balance Sort Icon")?.tinted(with: .themeJacob), for: .normal)
        sortButton.addTarget(self, action: #selector(_onTapSortType), for: .touchUpInside)

        addSubview(hideButton)
        hideButton.snp.makeConstraints { maker in
            maker.leading.equalTo(amountLabel.snp.trailing)
            maker.top.equalToSuperview()
            maker.width.equalTo(CGFloat.margin8x)
            maker.height.equalTo(BalanceHeaderView.height)
        }

        hideButton.setImage(UIImage(named: "Balance Hide Icon"), for: .normal)
        hideButton.addTarget(self, action: #selector(_onTapHide), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: BalanceHeaderViewItem) {
        amountLabel.text = ValueFormatter.instance.format(currencyValue: viewItem.currencyValue)
        amountLabel.textColor = viewItem.upToDate ? .themeJacob : .themeYellow50
        sortButton.isHidden = !viewItem.sortIsOn
    }

    @objc private func _onTapSortType() {
        onTapSortType?()
    }

    @objc private func _onTapHide() {
        onTapHide?()
    }

}
