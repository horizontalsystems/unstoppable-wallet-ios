import UIKit
import SnapKit
import ThemeKit
import HUD

class PostsHeaderFooterView: UITableViewHeaderFooterView {
    private let titleLabel = UILabel()
    private let spinner = HUDActivityView.create(with: .small20)
    private let bottomSeparator = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeClaude

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

        addSubview(bottomSeparator)
        bottomSeparator.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        bottomSeparator.backgroundColor = .themeSteel10
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
