import UIKit
import SnapKit

class BackupWordsController: WalletViewController {
    private let delegate: IBackupWordsViewDelegate

    private let scrollView = UIScrollView()
    private let wordsLabel = UILabel()

    private let proceedButtonHolder = GradientView(gradientHeight: BackupTheme.gradientHeight, viewHeight: BackupTheme.cancelHolderHeight, fromColor: BackupTheme.gradientTransparent, toColor: BackupTheme.gradientSolid)
    private let proceedButton = UIButton()

    init(delegate: IBackupWordsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        title = delegate.title.localized

        view.addSubview(scrollView)

        view.addSubview(proceedButtonHolder)
        proceedButtonHolder.addSubview(proceedButton)
        scrollView.addSubview(wordsLabel)

        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().offset(BackupTheme.sideMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        wordsLabel.numberOfLines = 0
        wordsLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(self.scrollView)
            maker.top.equalTo(self.scrollView).offset(BackupTheme.wordsTopMargin)
            maker.bottom.equalTo(self.scrollView.snp.bottom).offset(-BackupTheme.cancelHolderHeight)
        }

        proceedButtonHolder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            maker.height.equalTo(BackupTheme.cancelHolderHeight)
        }

        proceedButton.setTitle(delegate.isBackedUp ? "backup.close".localized : "button.next".localized, for: .normal)
        proceedButton.addTarget(self, action: #selector(nextDidTap), for: .touchUpInside)
        proceedButton.setBackgroundColor(color: BackupTheme.backupButtonBackground, forState: .normal)
        proceedButton.setTitleColor(BackupTheme.buttonTitleColor, for: .normal)
        proceedButton.titleLabel?.font = BackupTheme.buttonTitleFont
        proceedButton.cornerRadius = BackupTheme.buttonCornerRadius
        proceedButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.sideMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.bottom.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.height.equalTo(BackupTheme.buttonHeight)
        }


        let joinedWords = delegate.words.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")
        let attributedText = NSMutableAttributedString(string: joinedWords)
        attributedText.addAttribute(NSAttributedString.Key.font, value: UIFont.cryptoHeadline1, range: NSMakeRange(0, joinedWords.count))
        attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.crypto_White_Black, range: NSMakeRange(0, joinedWords.count))
        wordsLabel.attributedText = attributedText

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return App.theme.statusBarStyle
    }

    @objc func nextDidTap() {
        delegate.didTapProceed()
    }

}
