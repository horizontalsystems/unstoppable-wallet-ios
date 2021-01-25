import UIKit
import UIExtensions
import ThemeKit
import SnapKit

class MarketSectionHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = 55

    private let separatorView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let seeAllLabel = UILabel()
    private let seeAllClosureView = UIImageView()
    private let seeAllButton = UIButton()

    private var onTapSeeAll: (() -> ())?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .horizontal)

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(imageView.snp.trailing).offset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        titleLabel.textColor = .themeOz
        titleLabel.font = .body

        contentView.addSubview(seeAllLabel)
        seeAllLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        seeAllLabel.setContentHuggingPriority(.required, for: .horizontal)
        seeAllLabel.textColor = .themeGray
        seeAllLabel.font = .subhead1
        seeAllLabel.text = "market.top.section.header.see_all".localized

        contentView.addSubview(seeAllClosureView)
        seeAllClosureView.snp.makeConstraints { maker in
            maker.leading.equalTo(seeAllLabel.snp.trailing).offset(CGFloat.margin6)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        seeAllClosureView.image = UIImage(named: "arrow_big_forward_20")?.tinted(with: .themeGray)

        contentView.addSubview(seeAllButton)
        seeAllButton.snp.makeConstraints { maker in
            maker.leading.equalTo(seeAllLabel.snp.leading).inset(CGFloat.margin16)
            maker.trailing.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(image: UIImage?) {
        imageView.image = image
    }

    func set(title: String?) {
        titleLabel.text = title
    }

}
