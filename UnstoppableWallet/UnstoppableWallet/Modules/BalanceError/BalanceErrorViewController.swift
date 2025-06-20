
import MarketKit
import MessageUI
import RxSwift
import SnapKit

import UIKit

class BalanceErrorViewController: ThemeActionSheetController {
    private let viewModel: BalanceErrorViewModel
    private let disposeBag = DisposeBag()

    private weak var sourceViewController: UIViewController?

    private let titleView = BottomSheetTitleView()

    init(viewModel: BalanceErrorViewModel, sourceViewController: UIViewController?) {
        self.viewModel = viewModel
        self.sourceViewController = sourceViewController

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
            image: .warning,
            title: "balance_error.sync_error".localized,
            viewController: self
        )

        let retryButton = PrimaryButton()

        view.addSubview(retryButton)
        retryButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin24)
        }

        retryButton.addTarget(self, action: #selector(onTapRetry), for: .touchUpInside)
        retryButton.set(style: .yellow)
        retryButton.setTitle("button.retry".localized, for: .normal)

        var lastView: UIView = retryButton

        if viewModel.changeSourceVisible {
            let changeSourceButton = PrimaryButton()

            view.addSubview(changeSourceButton)
            changeSourceButton.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
                maker.top.equalTo(retryButton.snp.bottom).offset(CGFloat.margin12)
            }

            changeSourceButton.addTarget(self, action: #selector(onTapChangeSource), for: .touchUpInside)
            changeSourceButton.set(style: .gray)
            changeSourceButton.setTitle("balance_error.change_source".localized, for: .normal)

            lastView = changeSourceButton
        }

        let reportButton = PrimaryButton()

        view.addSubview(reportButton)
        reportButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(lastView.snp.bottom).offset(CGFloat.margin12)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

        reportButton.addTarget(self, action: #selector(onTapReport), for: .touchUpInside)
        reportButton.set(style: .transparent)
        reportButton.setTitle("button.report".localized, for: .normal)

        subscribe(disposeBag, viewModel.openBtcBlockchainSignal) { [weak self] in self?.openBtc(blockchain: $0) }
        subscribe(disposeBag, viewModel.openEvmBlockchainSignal) { [weak self] in self?.openEvm(blockchain: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.dismiss(animated: true) }
    }

    @objc private func onTapRetry() {
        viewModel.onTapRetry()
    }

    @objc private func onTapReport() {
        let email = AppConfig.reportEmail

        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.setToRecipients([email])
            controller.setMessageBody(viewModel.errorString, isHTML: false)
            controller.mailComposeDelegate = self

            present(controller, animated: true)
        } else {
            CopyHelper.copyAndNotify(value: email)
        }
    }

    @objc private func onTapChangeSource() {
        viewModel.onTapChangeSource()
    }

    private func openBtc(blockchain: Blockchain) {
        dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(BtcBlockchainSettingsModule.view(blockchain: blockchain).toNavigationViewController(), animated: true)
        }
    }

    private func openEvm(blockchain: Blockchain) {
        dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(EvmNetworkModule.viewController(blockchain: blockchain), animated: true)
        }
    }
}

extension BalanceErrorViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith _: MFMailComposeResult, error _: Error?) {
        controller.dismiss(animated: true)
    }
}
