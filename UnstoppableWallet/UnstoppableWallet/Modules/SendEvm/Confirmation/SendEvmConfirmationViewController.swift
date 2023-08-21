import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class SendEvmConfirmationViewController: SendEvmTransactionViewController {
    private let mode: Mode

    private let sendButton = PrimaryButton()
    private let sendSliderButton = SliderButton()

    init(mode: Mode, transactionViewModel: SendEvmTransactionViewModel, settingsViewModel: EvmSendSettingsViewModel) {
        self.mode = mode

        super.init(transactionViewModel: transactionViewModel, settingsViewModel: settingsViewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch mode {
        case .send:
            title = "confirm".localized

            bottomWrapper.addSubview(sendSliderButton)

            sendSliderButton.title = "send.confirmation.slide_to_send".localized
            sendSliderButton.finalTitle = "send.confirmation.sending".localized
            sendSliderButton.slideImage = UIImage(named: "arrow_medium_2_right_24")
            sendSliderButton.finalImage = UIImage(named: "check_2_24")
            sendSliderButton.onTap = { [weak self] in
                self?.transactionViewModel.send()
            }
        case .resend:
            title = "tx_info.options.speed_up".localized
            topDescription = "send.confirmation.resend_description".localized

            bottomWrapper.addSubview(sendButton)

            sendButton.set(style: .yellow)
            sendButton.setTitle("send.confirmation.resend".localized, for: .normal)
            sendButton.addTarget(self, action: #selector(onTapSend), for: .touchUpInside)
        case .cancel:
            title = "tx_info.options.cancel".localized
            topDescription = "send.confirmation.cancel_description".localized

            bottomWrapper.addSubview(sendButton)

            sendButton.set(style: .yellow)
            sendButton.setTitle("send.confirmation.cancel".localized, for: .normal)
            sendButton.addTarget(self, action: #selector(onTapSend), for: .touchUpInside)
        }

        subscribe(disposeBag, transactionViewModel.sendEnabledDriver) { [weak self] enabled in
            self?.sendSliderButton.isEnabled = enabled
            self?.sendButton.isEnabled = enabled
        }
    }

    @objc private func onTapSend() {
        transactionViewModel.send()
    }

    override func handleSending() {
        HudHelper.instance.show(banner: .sending)
    }

    override func handleSendSuccess(transactionHash: Data) {
        HudHelper.instance.show(banner: .sent)

        super.handleSendSuccess(transactionHash: transactionHash)
    }

    override func handleSendFailed(error: String) {
        super.handleSendFailed(error: error)

        sendSliderButton.reset()
    }

}

extension SendEvmConfirmationViewController {

    enum Mode {
        case send
        case resend
        case cancel
    }

}
