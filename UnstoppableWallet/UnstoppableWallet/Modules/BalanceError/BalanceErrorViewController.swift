import UIKit
import ThemeKit
import SnapKit

class BalanceErrorViewController: ThemeActionSheetController {
    private let delegate: IBalanceErrorViewDelegate

    private let titleView = BottomSheetTitleView()
    private let descriptionLabel = UILabel()
    private let retryButton = ThemeButton()
    private let changeSourceButton = ThemeButton()
    private let reportButton = ThemeButton()

    init(delegate: IBalanceErrorViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.onTapClose = { [weak self] in
            self?.delegate.onTapClose()
        }

        view.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin3x)
        }

        descriptionLabel.font = .subhead2
        descriptionLabel.textColor = .themeGray
        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = "balance_error.description".localized

        view.addSubview(retryButton)
        retryButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(descriptionLabel.snp.bottom).offset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        retryButton.addTarget(self, action: #selector(onTapRetry), for: .touchUpInside)
        retryButton.apply(style: .primaryYellow)
        retryButton.setTitle("button.retry".localized, for: .normal)

        view.addSubview(changeSourceButton)
        changeSourceButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(retryButton.snp.bottom).offset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        changeSourceButton.addTarget(self, action: #selector(onTapChangeSource), for: .touchUpInside)
        changeSourceButton.apply(style: .primaryGreen)
        changeSourceButton.setTitle("balance_error.change_source".localized, for: .normal)

        view.addSubview(reportButton)
        reportButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(changeSourceButton.snp.bottom).offset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
        }

        reportButton.addTarget(self, action: #selector(onTapReport), for: .touchUpInside)
        reportButton.apply(style: .primaryGray)
        reportButton.setTitle("button.report".localized, for: .normal)

        delegate.onLoad()
    }

    @objc private func onTapRetry() {
        delegate.onTapRetry()
    }

    @objc private func onTapReport() {
        delegate.onTapReport()
    }

    @objc private func onTapChangeSource() {
        delegate.onTapChangeSource()
    }

}

extension BalanceErrorViewController: IBalanceErrorView {

    func set(coinTitle: String) {
        titleView.bind(title: "balance_error.sync_error".localized, subtitle: coinTitle, image: UIImage(named: "Attention Icon")?.tinted(with: .themeLucian))
    }

    func setChangeSourceButton(hidden: Bool) {
        changeSourceButton.snp.remakeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(retryButton.snp.bottom).offset(hidden ? 0 : CGFloat.margin4x)
            maker.height.equalTo(hidden ? 0 : CGFloat.heightButton)
        }
    }

}
