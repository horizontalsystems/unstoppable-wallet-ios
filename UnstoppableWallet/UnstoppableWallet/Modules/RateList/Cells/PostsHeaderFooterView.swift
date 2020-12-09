import UIKit
import SnapKit
import ThemeKit
import HUD

class PostsHeaderFooterView: UITableViewHeaderFooterView {
    private let titleLabel = UILabel()
    private let spinner = HUDActivityView.create(with: .small20)
    private let topSeparator = UIView()
    private let bottomSeparator = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeLawrence

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        titleLabel.text = "rate_list.latest_news".localized
        titleLabel.font = .headline2
        titleLabel.textColor = .themeOz

        addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        addSubview(topSeparator)
        topSeparator.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        topSeparator.backgroundColor = .themeSteel20

        addSubview(bottomSeparator)
        bottomSeparator.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        bottomSeparator.backgroundColor = .themeSteel20
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(spinnerVisible: Bool) {
        if spinnerVisible {
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            spinner.isHidden = true
            spinner.stopAnimating()
        }
    }

}
