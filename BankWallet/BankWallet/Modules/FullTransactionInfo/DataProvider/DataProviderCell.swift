import UIKit
import UIExtensions
import HUD
import SnapKit

class DataProviderCell: AppCell {
    private static let spinnerSize: CGFloat = 12
    private static let spinnerStrokeWidth: CGFloat = 2

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let checkmarkImageView = TintImageView(
            image: UIImage(named: "Transaction Success Icon"),
            tintColor: .appJacob,
            selectedTintColor: .appJacob
    )

    private let spinnerView = HUDProgressView(
            strokeLineWidth: DataProviderCell.spinnerStrokeWidth,
            radius: DataProviderCell.spinnerSize / 2 - DataProviderCell.spinnerStrokeWidth / 2,
            strokeColor: .appGray
    )

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
        }

        titleLabel.font = .appBody
        titleLabel.textColor = .appOz

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.top.equalTo(titleLabel.snp.bottom).offset(3)
        }

        subtitleLabel.font = .appSubhead2

        contentView.addSubview(spinnerView)
        spinnerView.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)
            maker.size.equalTo(DataProviderCell.spinnerSize)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(6)
        }

        contentView.addSubview(checkmarkImageView)
        checkmarkImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalTo(contentView.snp.trailingMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String, online: Bool, checking: Bool, selected: Bool, last: Bool) {
        super.bind(last: last)

        titleLabel.text = title

        subtitleLabel.isHidden = checking
        spinnerView.isHidden = !checking

        if checking {
            spinnerView.startAnimating()
        } else {
            spinnerView.stopAnimating()

            if online {
                subtitleLabel.text = "full_info.source.online".localized
                subtitleLabel.textColor = .appRemus
            } else {
                subtitleLabel.text = "full_info.source.offline".localized
                subtitleLabel.textColor = .appLucian
            }
        }

        checkmarkImageView.isHidden = !selected
    }

}
