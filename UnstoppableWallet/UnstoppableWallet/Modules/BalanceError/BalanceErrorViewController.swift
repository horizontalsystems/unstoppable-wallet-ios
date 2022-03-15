import UIKit
import ThemeKit
import SnapKit
import MessageUI
import ComponentKit
import RxSwift

class BalanceErrorViewController: ThemeActionSheetController {
    private let viewModel: BalanceErrorViewModel
    private let disposeBag = DisposeBag()

    private weak var sourceViewController: UIViewController?

    private let titleView = BottomSheetTitleView()
    private let retryButton = ThemeButton()
    private let changeSourceButton = ThemeButton()
    private let reportButton = ThemeButton()

    init(viewModel: BalanceErrorViewModel, sourceViewController: UIViewController?) {
        self.viewModel = viewModel
        self.sourceViewController = sourceViewController

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

        titleView.bind(
                title: "balance_error.sync_error".localized,
                subtitle: viewModel.coinTitle,
                image: UIImage(named: "warning_2_24"),
                tintColor: .themeLucian
        )

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(retryButton)
        retryButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
            maker.height.equalTo(CGFloat.heightButton)
        }

        retryButton.addTarget(self, action: #selector(onTapRetry), for: .touchUpInside)
        retryButton.apply(style: .primaryYellow)
        retryButton.setTitle("button.retry".localized, for: .normal)

        let changeSourceVisible = viewModel.changeSourceVisible

        view.addSubview(changeSourceButton)
        changeSourceButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(retryButton.snp.bottom).offset(changeSourceVisible ? CGFloat.margin16 : 0)
            maker.height.equalTo(changeSourceVisible ? CGFloat.heightButton : 0)
        }

        changeSourceButton.addTarget(self, action: #selector(onTapChangeSource), for: .touchUpInside)
        changeSourceButton.apply(style: .primaryGray)
        changeSourceButton.setTitle("balance_error.change_source".localized, for: .normal)

        view.addSubview(reportButton)
        reportButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(changeSourceButton.snp.bottom).offset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

        reportButton.addTarget(self, action: #selector(onTapReport), for: .touchUpInside)
        reportButton.apply(style: .primaryGray)
        reportButton.setTitle("button.report".localized, for: .normal)

        subscribe(disposeBag, viewModel.openBtcBlockchainSignal) { [weak self] in self?.openBtc(blockchain: $0) }
        subscribe(disposeBag, viewModel.openEvmBlockchainSignal) { [weak self] in self?.openEvm(blockchain: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.dismiss(animated: true) }
    }

    @objc private func onTapRetry() {
        viewModel.onTapRetry()
    }

    @objc private func onTapReport() {
        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.setToRecipients([viewModel.email])
            controller.setMessageBody(viewModel.errorString, isHTML: false)
            controller.mailComposeDelegate = self

            present(controller, animated: true)
        } else {
            UIPasteboard.general.setValue(viewModel.email, forPasteboardType: "public.plain-text")
            HudHelper.instance.showSuccess(title: "settings.about_app.email_copied".localized)
        }
    }

    @objc private func onTapChangeSource() {
        viewModel.onTapChangeSource()
    }

    private func openBtc(blockchain: BtcBlockchain) {
        dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(BtcBlockchainSettingsModule.viewController(blockchain: blockchain), animated: true)
        }
    }

    private func openEvm(blockchain: EvmBlockchain) {
        dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(EvmNetworkModule.viewController(blockchain: blockchain), animated: true)
        }
    }

}

extension BalanceErrorViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }

}
