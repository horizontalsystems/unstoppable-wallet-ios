import SnapKit
import UIKit

class ReleaseNotesViewController: MarkdownViewController {
    private let urlManager: UrlManager
    private let presented: Bool
    private let closeHandler: (() -> Void)?

    let bottomHolder = UIView()

    init(viewModel: MarkdownViewModel, handleRelativeUrl: Bool, urlManager: UrlManager, presented: Bool, closeHandler: (() -> Void)? = nil) {
        self.urlManager = urlManager
        self.presented = presented
        self.closeHandler = closeHandler

        super.init(viewModel: viewModel, handleRelativeUrl: handleRelativeUrl)

        navigationItem.largeTitleDisplayMode = .automatic
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        title = "release_notes.title".localized

        if presented {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))
        }

        super.viewDidLoad()

        bottomHolder.backgroundColor = .themeTyler

        let separator = UIView()
        bottomHolder.addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1)
        }

        separator.backgroundColor = .themeBlade

        let twitterButton = UIButton()
        bottomHolder.addSubview(twitterButton)
        twitterButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin8)
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(52)
        }

        twitterButton.addTarget(self, action: #selector(onTwitterTap), for: .touchUpInside)
        twitterButton.setImage(UIImage(named: "filled_twitter_24")?.withTintColor(.themeJacob), for: .normal)

        let telegramButton = UIButton()
        bottomHolder.addSubview(telegramButton)
        telegramButton.snp.makeConstraints { maker in
            maker.leading.equalTo(twitterButton.snp.trailing).offset(CGFloat.margin8)
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(52)
        }

        telegramButton.addTarget(self, action: #selector(onTelegramTap), for: .touchUpInside)
        telegramButton.setImage(UIImage(named: "filled_telegram_24")?.withTintColor(.themeJacob), for: .normal)

        let followUsLabel = UILabel()
        bottomHolder.addSubview(followUsLabel)
        followUsLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin24)
        }

        followUsLabel.font = .caption
        followUsLabel.textColor = .themeJacob
        followUsLabel.text = "release_notes.follow_us".localized
    }

    override func makeTableViewConstraints(tableView: UIView) {
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        view.addSubview(bottomHolder)
        bottomHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            maker.height.equalTo(83)
        }
    }

    @objc private func onClose() {
        dismiss(animated: true, completion: { [weak self] in
            self?.closeHandler?()
        })
    }

    @objc private func onTwitterTap() {
        urlManager.open(url: "https://twitter.com/\(AppConfig.appTwitterAccount)", from: nil)
    }

    @objc private func onTelegramTap() {
        urlManager.open(url: "https://t.me/\(AppConfig.appTelegramAccount)", from: nil)
    }
}

extension ReleaseNotesViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_: UIPresentationController) {
        closeHandler?()
    }
}
