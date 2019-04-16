import UIKit
import SnapKit

class BackupWordsController: WalletViewController {

    let delegate: IBackupViewDelegate

    let wordsLabel = UILabel()
    let proceedButton = UIButton()

    let words: [String]

    init(words: [String], delegate: IBackupViewDelegate) {
        self.words = words
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        title = "backup.words.title".localized

        view.addSubview(wordsLabel)
        view.addSubview(proceedButton)

        wordsLabel.numberOfLines = 0
        wordsLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.sideMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.top.equalTo(self.view.snp.topMargin).offset(BackupTheme.wordsTopMargin)
            maker.bottom.lessThanOrEqualTo(self.proceedButton.snp.top).offset(-BackupTheme.wordsBottomMargin)
        }

        proceedButton.setTitle("backup.words.proceed".localized, for: .normal)
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


        let joinedWords = words.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")
        let attributedText = NSMutableAttributedString(string: joinedWords)
        attributedText.addAttribute(NSAttributedString.Key.font, value: UIFont.cryptoTitle4, range: NSMakeRange(0, joinedWords.count))
        attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.crypto_White_Black, range: NSMakeRange(0, joinedWords.count))
        wordsLabel.attributedText = attributedText

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @objc func nextDidTap() {
        delegate.showConfirmationDidClick()
    }

}
