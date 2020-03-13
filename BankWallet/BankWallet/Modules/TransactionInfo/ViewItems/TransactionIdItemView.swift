import UIKit
import ActionSheet
import SnapKit

class TransactionIdItemView: BaseActionItemView {
    private let titleLabel = UILabel()
    private let hashView = HashView()
    private let shareButton = UIButton.appSecondary

    override var item: TransactionIdItem? { return _item as? TransactionIdItem }

    override func initView() {
        super.initView()

        backgroundColor = .themeLawrence

        addSubview(titleLabel)
        addSubview(hashView)
        addSubview(shareButton)

        titleLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.font = .subhead2
        titleLabel.textColor = .themeGray
        titleLabel.text = "tx_info.transaction_id".localized

        hashView.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel.snp.trailing).offset(CGFloat.margin12x)
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(shareButton.snp.leading).offset(-CGFloat.margin1x)
        }

        shareButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButtonSecondary)
            maker.width.equalTo(CGFloat.heightButtonSecondary)
        }
        shareButton.imageEdgeInsets = UIEdgeInsets(top: -.margin2x, left: -.margin2x, bottom: -.margin2x, right: -.margin2x)
        shareButton.setImage(UIImage(named: "Share Transaction Icon")?.tinted(with: .themeLeah), for: .normal)
        shareButton.addTarget(self, action: #selector(onTapShare), for: .touchUpInside)
    }

    override func updateView() {
        super.updateView()

        hashView.bind(value: item?.value, showExtra: .hash, onTap: item?.onHashTap)
    }

    @objc func onTapShare() {
        item?.onShareTap?()
    }

}
