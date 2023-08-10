import Combine
import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import Alamofire
import Kingfisher
import HUD

class DepositViewController: ThemeViewController {
    private let qrCodeSideMargin: CGFloat = 72
    private let smallScreenQrCodeSideMargin: CGFloat = 88

    private var cancellables = Set<AnyCancellable>()

    private let viewModel: DepositViewModel

    private let spinner = HUDActivityView.create(with: .medium24)
    private let spinnerView = UIView()
    private let errorView = PlaceholderView()
    private let qrCodeImageView = UIImageView()
    private let testnetImageView = UIImageView()

    private let stackView = UIStackView()
    private let addressTitleLabel = UILabel()
    private let addressLabel = UILabel()
    private let infoButton = UIButton()

    private var margin: CGFloat { view.width > 320 ? qrCodeSideMargin : smallScreenQrCodeSideMargin }

    private var viewItem: DepositViewModel.ViewItem?

    init(viewModel: DepositViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        let topWrapperView = UIView()

        view.addSubview(topWrapperView)
        topWrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide)
        }

        let contentWrapperView = UIView()

        topWrapperView.addSubview(contentWrapperView)
        contentWrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }


        contentWrapperView.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(margin)
            maker.top.equalToSuperview()
            maker.width.equalTo(qrCodeImageView.snp.height)
        }

        qrCodeImageView.isUserInteractionEnabled = true
        qrCodeImageView.backgroundColor = .white
        qrCodeImageView.contentMode = .center
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.cornerRadius = .cornerRadius8
        qrCodeImageView.layer.cornerCurve = .continuous

        let qrCodeRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapCopy))
        qrCodeImageView.addGestureRecognizer(qrCodeRecognizer)

        view.addSubview(testnetImageView)
        testnetImageView.snp.makeConstraints { maker in
            maker.top.equalTo(qrCodeImageView.snp.bottom)
            maker.centerX.equalToSuperview()
        }

        testnetImageView.image = UIImage(named: "testnet_24")?.withRenderingMode(.alwaysTemplate)
        testnetImageView.tintColor = .themeRed50
        testnetImageView.isHidden = true

        contentWrapperView.addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(qrCodeImageView.snp.bottom).offset(CGFloat.margin24)
        }

        stackView.spacing = 0
        stackView.alignment = .center

        addressTitleLabel.setContentHuggingPriority(.required, for: .horizontal)
        stackView.addArrangedSubview(addressTitleLabel)

        addressTitleLabel.numberOfLines = 0

        let infoButton = UIButton()
        infoButton.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.margin24)
        }

        stackView.addArrangedSubview(infoButton)
        infoButton.addTarget(self, action: #selector(onInfoButton), for: .touchUpInside)
        infoButton.isHidden = true

        let addressLabelWrapper = UIView()

        contentWrapperView.addSubview(addressLabelWrapper)
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
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        addressLabel.textAlignment = .center
        addressLabel.numberOfLines = 0
        addressLabel.font = .subhead1
        addressLabel.textColor = .themeBran

        let copyButton = PrimaryButton()

        view.addSubview(copyButton)
        copyButton.snp.makeConstraints { maker in
            maker.top.equalTo(topWrapperView.snp.bottom).offset(CGFloat.margin24)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        copyButton.set(style: .yellow)
        copyButton.setTitle("button.copy".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)
        copyButton.setContentHuggingPriority(.defaultHigh, for: .vertical)

        let shareButton = PrimaryButton()

        view.addSubview(shareButton)
        shareButton.snp.makeConstraints { maker in
            maker.top.equalTo(copyButton.snp.bottom).offset(CGFloat.margin16)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(44)
        }

        shareButton.set(style: .gray)
        shareButton.setTitle("button.share".localized, for: .normal)
        shareButton.addTarget(self, action: #selector(onTapShare), for: .touchUpInside)

        view.addSubview(spinnerView)
        spinnerView.backgroundColor = view.backgroundColor
        spinnerView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        spinnerView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinnerView.isHidden = true

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.image = UIImage(named: "sync_error_48")
        errorView.text = "sync_error".localized
        errorView.isHidden = true

        viewModel.loadingPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] loading in
                    self?.show(loading)
                }
                .store(in: &cancellables)

        viewModel.errorPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] error in
                    self?.show(error)
                }
                .store(in: &cancellables)

        viewModel.viewItemPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] viewItem in
                    self?.show(viewItem)
                }
                .store(in: &cancellables)
    }

    @objc private func onTapCopy() {
        guard let address = viewItem?.address else {
            return
        }
        CopyHelper.copyAndNotify(value: address)
    }

    @objc private func onInfoButton() {
        guard case let .warning(_, title, text) = viewItem?.additionalInfo else {
            return
        }

        present(BottomSheetModule.description(title: title, text: text), animated: true)
    }

    @objc private func onTapShare() {
        guard let address = viewItem?.address else {
            return
        }

        let activityViewController = UIActivityViewController(activityItems: [address], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func show(_ loading: Bool) {
        spinnerView.isHidden = !loading
        if loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    private func show(_ error: String?) {
        guard let error else {
            errorView.isHidden = true
            return
        }

        errorView.isHidden = false
        errorView.text = error
    }

    private func show(_ viewItem: DepositViewModel.ViewItem?) {
        self.viewItem = viewItem
        guard let viewItem else {
            return
        }

        let size = view.width - 2 * margin
        qrCodeImageView.asyncSetImage { UIImage.qrCodeImage(qrCodeString: viewItem.address, size: size)  }

        testnetImageView.isHidden = viewItem.isMainNet

        if case .warning = viewItem.additionalInfo {
            infoButton.isHidden = false
            infoButton.setImage(UIImage(named: "circle_information_20")?.withTintColor(.themeJacob), for: .normal)
        } else {
            infoButton.isHidden = true
        }

        addressTitleLabel.attributedText = viewItem.title
        addressLabel.text = viewItem.address
    }

}
