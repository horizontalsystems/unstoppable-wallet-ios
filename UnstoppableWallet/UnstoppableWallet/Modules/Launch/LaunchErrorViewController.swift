import UIKit
import MessageUI
import SnapKit
import ThemeKit
import ComponentKit

class LaunchErrorViewController: ThemeViewController {
    private let error: Error

    init(error: Error) {
        self.error = error

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let wrapperView = UIView()
        view.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            make.centerY.equalToSuperview()
        }

        let iconImageView = UIImageView()
        wrapperView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        iconImageView.contentMode = .center
        iconImageView.image = UIImage(named: "attention_48")?.withTintColor(.themeGray)

        let infoLabel = UILabel()
        wrapperView.addSubview(infoLabel)
        infoLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(CGFloat.margin32)
        }

        infoLabel.textColor = .themeGray
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.font = .body
        infoLabel.text = "launch.failed_to_launch".localized

        let reportButton = PrimaryButton()
        wrapperView.addSubview(reportButton)
        reportButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(infoLabel.snp.bottom).offset(CGFloat.margin32)
            make.bottom.equalToSuperview()
        }

        reportButton.set(style: .gray)
        reportButton.setTitle("launch.failed_to_launch.report".localized, for: .normal)
        reportButton.addTarget(self, action: #selector(onTapReport), for: .touchUpInside)
    }

    @objc private func onTapReport() {
        let errorString = """
                          Raw Error: \(error)
                          Localized Description: \(error.localizedDescription)
                          """

        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.setToRecipients([AppConfig.reportEmail])
            controller.setMessageBody(errorString, isHTML: false)
            controller.mailComposeDelegate = self

            present(controller, animated: true)
        } else {
            CopyHelper.copyAndNotify(value: errorString)
        }
    }

}

extension LaunchErrorViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }

}
