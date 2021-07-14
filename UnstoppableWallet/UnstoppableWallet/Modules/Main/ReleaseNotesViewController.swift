import UIKit
import ThemeKit
import SnapKit

class ReleaseNotesViewController: ThemeViewController {
    private let markdownController: UIViewController
    private let urlManager: IUrlManager

    private let closeHandler: (() -> ())?

    init(url: URL, urlManager: IUrlManager, closeHandler: (() -> ())? = nil) {
        markdownController = MarkdownModule.gitReleaseNotesMarkdownViewController(url: url)
        self.urlManager = urlManager
        self.closeHandler = closeHandler

        super.init()

        navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))

        let bottomHolder = UIView()
        view.addSubview(bottomHolder)
        bottomHolder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            maker.height.equalTo(83)
        }

        bottomHolder.backgroundColor = .themeTyler

        let separator = UIView()
        bottomHolder.addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1)
        }

        separator.backgroundColor = .themeSteel10

        view.addSubview(markdownController.view)
        markdownController.view.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(bottomHolder.snp.top)
        }

        let twitterButton = UIButton()
        bottomHolder.addSubview(twitterButton)
        twitterButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin8)
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(52)
        }

        twitterButton.addTarget(self, action: #selector(onTwitterTap), for: .touchUpInside)
        twitterButton.setImage(UIImage(named: "filled_twitter_24"), for: .normal)

        let telegramButton = UIButton()
        bottomHolder.addSubview(telegramButton)
        telegramButton.snp.makeConstraints { maker in
            maker.leading.equalTo(twitterButton.snp.trailing).offset(CGFloat.margin8)
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(52)
        }

        telegramButton.addTarget(self, action: #selector(onTelegramTap), for: .touchUpInside)
        telegramButton.setImage(UIImage(named: "filled_telegram_24"), for: .normal)

        let redditButton = UIButton()
        bottomHolder.addSubview(redditButton)
        redditButton.snp.makeConstraints { maker in
            maker.leading.equalTo(telegramButton.snp.trailing).offset(CGFloat.margin8)
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(52)
        }

        redditButton.addTarget(self, action: #selector(onRedditTap), for: .touchUpInside)
        redditButton.setImage(UIImage(named: "filled_reddit_24"), for: .normal)

        let followUsLabel = UILabel()
        bottomHolder.addSubview(followUsLabel)
        followUsLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().inset(CGFloat.margin24)
        }

        followUsLabel.font = .caption
        followUsLabel.textColor = .themeGray
        followUsLabel.text = "release_notes.follow_us".localized
    }

    @objc private func onClose() {
        dismiss(animated: true, completion: { [weak self] in
            self?.closeHandler?()
        })
    }

    @objc private func onTwitterTap() {
        urlManager.open(url: "https://twitter.com/unstoppablebyhs", from: nil)
    }

    @objc private func onTelegramTap() {
        urlManager.open(url: "https://t.me/unstoppable_announcements", from: nil)
    }

    @objc private func onRedditTap() {
        urlManager.open(url: "https://www.reddit.com/r/UNSTOPPABLEWallet", from: nil)
    }

}
