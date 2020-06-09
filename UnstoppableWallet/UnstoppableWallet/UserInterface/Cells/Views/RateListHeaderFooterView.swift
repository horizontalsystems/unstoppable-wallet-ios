import UIKit
import ThemeKit

class RateListHeaderFooterView: UITableViewHeaderFooterView {
    static let height: CGFloat = 66

    private let dateLabel = UILabel()
    private let separatorView = UIView()
    private let titleLabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin1x)
        }

        dateLabel.font = .caption
        dateLabel.textColor = .themeGray

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin3x)
        }

        titleLabel.font = .headline2
        titleLabel.textColor = .themeOz

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(titleLabel.snp.top).offset(-CGFloat.margin3x)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(title: String, lastUpdated: Date?) {
        titleLabel.text = title
        dateLabel.text = lastUpdated.map { DateHelper.instance.formatRateListTitle(from: $0) }
    }

}
