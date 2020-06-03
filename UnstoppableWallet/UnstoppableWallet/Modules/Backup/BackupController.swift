import UIKit
import SnapKit
import ThemeKit

class BackupController: ThemeViewController {
    private let delegate: IBackupViewDelegate

    private let descriptionView = HighlightedDescriptionView()
    private let cancelButton = ThemeButton()
    private let proceedButton = ThemeButton()

    init(delegate: IBackupViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = delegate.isBackedUp ? "backup.intro.title_show".localized : "backup.intro.title_backup".localized

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(self.view.snp.topMargin).offset(CGFloat.margin3x)
        }

        descriptionView.bind(text: "backup.intro.subtitle".localized(delegate.coinCodes))

        view.addSubview(proceedButton)
        proceedButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        proceedButton.apply(style: .primaryYellow)
        proceedButton.setTitle(delegate.isBackedUp ? "backup.intro.show_key".localized : "backup.intro.backup_now".localized, for: .normal)
        proceedButton.addTarget(self, action: #selector(proceedDidTap), for: .touchUpInside)

        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(proceedButton.snp.bottom).offset(CGFloat.margin4x)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        cancelButton.apply(style: .primaryGray)
        cancelButton.setTitle(delegate.isBackedUp ? "backup.close".localized : "backup.intro.later".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelDidTap), for: .touchUpInside)
    }

    @objc func proceedDidTap() {
        delegate.proceedDidTap()
    }

    @objc func cancelDidTap() {
        delegate.cancelDidClick()
    }

}
