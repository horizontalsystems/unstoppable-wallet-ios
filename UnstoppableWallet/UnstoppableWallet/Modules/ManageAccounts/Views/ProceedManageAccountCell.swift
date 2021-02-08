import UIKit

class ProceedManageAccountCell: BaseManageAccountCell {
    static let height: CGFloat = .heightCell48

    private let titleLabel = UILabel()
    private let warningImageView = UIImageView(image: UIImage(named: "warning_2_20")?.tinted(with: .themeLucian))
    private let disclosureImageView = UIImageView(image: UIImage(named: "arrow_big_forward_20"))

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentHolder.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        titleLabel.font = .body

        contentHolder.addSubview(warningImageView)
        warningImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
        }

        contentHolder.addSubview(disclosureImageView)
        disclosureImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(warningImageView.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(state: ManageAccountButtonState, highlighted: Bool, position: CellPosition) {
        super.bind(position: position, highlighted: highlighted, height: ProceedManageAccountCell.height)

        switch state {
        case .create:
            titleLabel.text = "settings_manage_keys.create".localized
            titleLabel.textColor = .themeJacob
            warningImageView.isHidden = true
            disclosureImageView.isHidden = true
        case .backup:
            titleLabel.text = "settings_manage_keys.backup".localized
            titleLabel.textColor = .themeLeah
            warningImageView.isHidden = false
            disclosureImageView.isHidden = false
        case .show:
            titleLabel.text = "settings_manage_keys.show".localized
            titleLabel.textColor = .themeLeah
            warningImageView.isHidden = true
            disclosureImageView.isHidden = false
        case .restore:
            titleLabel.text = "settings_manage_keys.restore".localized
            titleLabel.textColor = .themeJacob
            warningImageView.isHidden = true
            disclosureImageView.isHidden = true
        case .delete:
            titleLabel.text = "settings_manage_keys.delete".localized
            titleLabel.textColor = .themeLucian
            warningImageView.isHidden = true
            disclosureImageView.isHidden = true
        case .settings:
            titleLabel.text = "settings_manage_keys.settings".localized
            titleLabel.textColor = .themeLeah
            warningImageView.isHidden = true
            disclosureImageView.isHidden = false
        }
    }

}
