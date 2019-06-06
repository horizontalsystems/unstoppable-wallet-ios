import UIKit
import UIExtensions
import SnapKit

class SyncModeCell: UITableViewCell {
    var highlightBackground = UIView()

    var titleLabel = UILabel()
    var descriptionLabel = UILabel()

    var selectedImageView = UIImageView(image: UIImage(named: "Confirmations Icon")?.tinted(with: SyncModeTheme.selectedColor))

    let topSeparatorView = UIView()
    let bottomSeparatorView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = SyncModeTheme.cellBackground
        selectionStyle = .none

        highlightBackground.backgroundColor = SyncModeTheme.cellHighlightBackgroundColor
        highlightBackground.alpha = 0
        contentView.addSubview(highlightBackground)
        highlightBackground.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        titleLabel.font = SyncModeTheme.titleFont
        titleLabel.textColor = SyncModeTheme.titleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)//.offset(SyncModeTheme.leftAdditionalMargin)
            maker.top.equalToSuperview().offset(SyncModeTheme.cellMediumMargin)
        }
        descriptionLabel.font = SyncModeTheme.descriptionFont
        descriptionLabel.textColor = SyncModeTheme.descriptionColor
        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(contentView.snp.leadingMargin)//.offset(SyncModeTheme.leftAdditionalMargin)
            maker.top.equalTo(titleLabel.snp.bottom).offset(SyncModeTheme.cellSmallMargin)
        }

        contentView.addSubview(selectedImageView)
        selectedImageView.snp.makeConstraints { maker in
            maker.trailing.equalTo(contentView.snp.trailingMargin)//.offset(SyncModeTheme.cellSmallMargin)
            maker.centerY.equalToSuperview()
        }

        topSeparatorView.backgroundColor = AppTheme.separatorColor
        addSubview(topSeparatorView)
        topSeparatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
        bottomSeparatorView.backgroundColor = AppTheme.separatorColor
        addSubview(bottomSeparatorView)
        bottomSeparatorView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(title: String, description: String, selected: Bool, first: Bool, last: Bool) {
        titleLabel.text = title
        descriptionLabel.text = description
        selectedImageView.isHidden = !selected

        topSeparatorView.isHidden = !first
        bottomSeparatorView.backgroundColor = last ? AppTheme.darkSeparatorColor : AppTheme.separatorColor
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.highlightBackground.alpha = highlighted ? 1 : 0
            }
        } else {
            highlightBackground.alpha = highlighted ? 1 : 0
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        guard selectionStyle != .none else { return }
        if animated {
            UIView.animate(withDuration: AppTheme.defaultAnimationDuration) {
                self.highlightBackground.alpha = selected ? 1 : 0
            }
        } else {
            highlightBackground.alpha = selected ? 1 : 0
        }
    }

}
