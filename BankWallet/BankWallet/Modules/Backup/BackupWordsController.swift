import UIKit

class BackupWordsController: UIViewController {

    let delegate: IBackupViewDelegate

    @IBOutlet weak var wordsLabel: UILabel?
    @IBOutlet weak var proceedButton: UIButton?

    let words: [String]

    init(words: [String], delegate: IBackupViewDelegate) {
        self.words = words
        self.delegate = delegate

        super.init(nibName: String(describing: BackupWordsController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.controllerBackground

        title = "backup.words.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        proceedButton?.setTitle("backup.words.proceed".localized, for: .normal)

        let joinedWords = words.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")
        let attributedText = wordsLabel?.attributedText as? NSMutableAttributedString
        attributedText?.mutableString.setString(joinedWords)
        attributedText?.addAttribute(NSAttributedStringKey.font, value: UIFont.cryptoTitle3, range: NSMakeRange(0, joinedWords.count))
        attributedText?.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.crypto_White_Black, range: NSMakeRange(0, joinedWords.count))
        wordsLabel?.attributedText = attributedText

    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @IBAction func nextDidTap() {
        delegate.showConfirmationDidClick()
    }

    @IBAction func backDidTap() {
        delegate.hideWordsDidClick()
    }

}
