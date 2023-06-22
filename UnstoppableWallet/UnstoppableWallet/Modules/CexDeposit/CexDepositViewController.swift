import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import HUD

class CexDepositViewController: ThemeViewController {
    private let maxQrCodeSize: CGFloat = 230

    private let viewModel: CexDepositViewModel
    private var cancellables = Set<AnyCancellable>()

    private let spinner = HUDActivityView.create(with: .medium24)
    private let failedView = PlaceholderView()
    private let addressView = UIView()
    private let addressLabel = UILabel()
    private let qrCodeImageView = UIImageView()

    init(viewModel: CexDepositViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.networkName

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDone))

        view.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        spinner.startAnimating()

        view.addSubview(failedView)
        failedView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        failedView.image = UIImage(named: "sync_error_48")
        failedView.text = "cex_deposit.failed".localized
        failedView.addPrimaryButton(
                style: .yellow,
                title: "button.retry".localized,
                target: self,
                action: #selector(onTapRetry)
        )

        view.addSubview(addressView)
        addressView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        let warningView = HighlightedDescriptionView()
        addressView.addSubview(warningView)
        warningView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalToSuperview().inset(CGFloat.margin12)
        }

        warningView.text = "cex_deposit.warning".localized(viewModel.coinCode)
        warningView.setContentHuggingPriority(.required, for: .vertical)

        let contentView = UIView()
        addressView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(warningView.snp.bottom).offset(CGFloat.margin24)
        }

        let wrapperView = UIView()
        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        let qrCodeImageWrapper = UIView()
        wrapperView.addSubview(qrCodeImageWrapper)
        qrCodeImageWrapper.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalTo(qrCodeImageWrapper.snp.height)
            make.height.lessThanOrEqualTo(maxQrCodeSize)
            make.height.equalTo(maxQrCodeSize).priority(.high)
        }

        qrCodeImageWrapper.isUserInteractionEnabled = true
        qrCodeImageWrapper.backgroundColor = .white
        qrCodeImageWrapper.layer.cornerRadius = .cornerRadius8
        qrCodeImageWrapper.layer.cornerCurve = .continuous

        let qrCodeRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapCopy))
        qrCodeImageView.addGestureRecognizer(qrCodeRecognizer)

        qrCodeImageWrapper.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(CGFloat.margin4)
        }

        qrCodeImageView.isUserInteractionEnabled = true
        qrCodeImageView.backgroundColor = .white
        qrCodeImageView.contentMode = .scaleToFill
        qrCodeImageView.clipsToBounds = true

        let addressTitleLabel = UILabel()
        wrapperView.addSubview(addressTitleLabel)
        addressTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin32)
            make.top.equalTo(qrCodeImageWrapper.snp.bottom).offset(CGFloat.margin32)
        }

        addressTitleLabel.numberOfLines = 0
        addressTitleLabel.textAlignment = .center
        addressTitleLabel.font = .subhead2
        addressTitleLabel.textColor = .themeGray
        addressTitleLabel.text = "cex_deposit.address_title".localized(viewModel.coinCode, viewModel.networkName)
        addressTitleLabel.setContentHuggingPriority(.required, for: .vertical)
        addressTitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let addressLabelWrapper = UIView()
        wrapperView.addSubview(addressLabelWrapper)
        addressLabelWrapper.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(addressTitleLabel.snp.bottom)
            maker.bottom.equalToSuperview()
        }

        let addressRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapCopy))
        addressLabelWrapper.isUserInteractionEnabled = true
        addressLabelWrapper.addGestureRecognizer(addressRecognizer)

        addressLabelWrapper.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin32)
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        addressLabel.textAlignment = .center
        addressLabel.numberOfLines = 0
        addressLabel.font = .subhead1
        addressLabel.textColor = .themeLeah
        addressLabel.setContentHuggingPriority(.required, for: .vertical)
        addressLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let copyButton = PrimaryButton()
        addressView.addSubview(copyButton)
        copyButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalTo(contentView.snp.bottom).offset(CGFloat.margin12)
        }

        copyButton.set(style: .yellow)
        copyButton.setTitle("button.copy".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)

        let shareButton = PrimaryButton()
        addressView.addSubview(shareButton)
        shareButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalTo(copyButton.snp.bottom).offset(CGFloat.margin16)
            make.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

        shareButton.set(style: .gray)
        shareButton.setTitle("button.share".localized, for: .normal)
        shareButton.addTarget(self, action: #selector(onTapShare), for: .touchUpInside)

        viewModel.$spinnerVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.spinner.isHidden = !$0 }
                .store(in: &cancellables)

        viewModel.$errorVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.failedView.isHidden = !$0 }
                .store(in: &cancellables)

        viewModel.$address
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.sync(address: $0) }
                .store(in: &cancellables)
    }

    private func sync(address: String?) {
        if let address {
            addressView.isHidden = false
            addressLabel.text = address

            let size = qrCodeImageView.height
            qrCodeImageView.asyncSetImage { UIImage.qrCodeImage(qrCodeString: address, size: size)  }
        } else {
            addressView.isHidden = true
        }
    }

    @objc private func onTapDone() {
        dismiss(animated: true)
    }

    @objc private func onTapRetry() {
        viewModel.onTapRetry()
    }

    @objc private func onTapCopy() {
        guard let address = viewModel.address else {
            return
        }

        CopyHelper.copyAndNotify(value: address)
    }

    @objc private func onTapShare() {
        guard let address = viewModel.address else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [address], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }

}
