import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD

class RestoreBinanceViewController: ThemeViewController {
    private let viewModel: RestoreBinanceViewModel
    private var cancellables = Set<AnyCancellable>()

    private weak var returnViewController: UIViewController?

    private let tableView = SectionsTableView(style: .grouped)

    private let apiKeyCell = PasteInputCell()
    private let secretKeyCell = PasteInputCell()

    private let connectButton = PrimaryButton()
    private let connectingButton = PrimaryButton()

    private var isLoaded = false

    init(viewModel: RestoreBinanceViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.returnViewController = returnViewController

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Cex.binance.title

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "qr_scan_24"), style: .plain, target: self, action: #selector(onTapScanQr))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        apiKeyCell.isEditable = false
        apiKeyCell.inputPlaceholder = "restore.binance.api_key".localized
        apiKeyCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        apiKeyCell.onChangeText = { [weak self] in self?.viewModel.onChange(apiKey: $0 ?? "") }
        apiKeyCell.onFetchText = { [weak self] in
            self?.viewModel.onChange(apiKey: $0 ?? "")
            self?.apiKeyCell.inputText = $0
        }

        secretKeyCell.isEditable = false
        secretKeyCell.inputPlaceholder = "restore.binance.secret_key".localized
        secretKeyCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        secretKeyCell.onChangeText = { [weak self] in self?.viewModel.onChange(secretKey: $0 ?? "") }
        secretKeyCell.onFetchText = { [weak self] in
            self?.viewModel.onChange(secretKey: $0 ?? "")
            self?.secretKeyCell.inputText = $0
        }

        let buttonsHolder = BottomGradientHolder()
        view.addSubview(buttonsHolder)
        buttonsHolder.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let stackView = UIStackView()

        buttonsHolder.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(CGFloat.margin24)
        }

        stackView.axis = .vertical
        stackView.spacing = .margin16

        stackView.addArrangedSubview(connectButton)
        connectButton.set(style: .yellow)
        connectButton.setTitle("restore.binance.connect".localized, for: .normal)
        connectButton.addTarget(self, action: #selector(onTapConnect), for: .touchUpInside)

        stackView.addArrangedSubview(connectingButton)
        connectingButton.set(style: .yellow, accessoryType: .spinner)
        connectingButton.isEnabled = false
        connectingButton.setTitle("restore.binance.connecting".localized, for: .normal)

        let getApiKeysButton = PrimaryButton()
        stackView.addArrangedSubview(getApiKeysButton)
        getApiKeysButton.set(style: .transparent)
        getApiKeysButton.setTitle("restore.binance.get_api_keys".localized, for: .normal)
        getApiKeysButton.addTarget(self, action: #selector(onTapGetApiKeys), for: .touchUpInside)

        viewModel.$connectEnabled
                .receive(on: DispatchQueue.main)
                .sink { [weak self] enabled in self?.connectButton.isEnabled = enabled }
                .store(in: &cancellables)

        viewModel.$connectVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] visible in self?.connectButton.isHidden = !visible }
                .store(in: &cancellables)

        viewModel.$connectingVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] visible in self?.connectingButton.isHidden = !visible }
                .store(in: &cancellables)

        viewModel.valuesPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] apiKey, secretKey in
                    self?.apiKeyCell.inputText = apiKey
                    self?.secretKeyCell.inputText = secretKey
                }
                .store(in: &cancellables)

        viewModel.errorPublisher
                .receive(on: DispatchQueue.main)
                .sink { text in HudHelper.instance.showErrorBanner(title: text) }
                .store(in: &cancellables)

        viewModel.successPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    HudHelper.instance.show(banner: .imported)
                    (self?.returnViewController ?? self)?.dismiss(animated: true)
                }
                .store(in: &cancellables)

        tableView.buildSections()
        isLoaded = true
    }

    private func reloadHeights() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    @objc private func onTapScanQr() {
        let scanQrViewController = ScanQrViewController()
        scanQrViewController.delegate = self
        present(scanQrViewController, animated: true)
    }

    @objc private func onTapConnect() {
        viewModel.onTapConnect()
    }

    @objc private func onTapGetApiKeys() {
        UrlManager.open(url: "https://www.binance.com/en/my/settings/api-management")
    }

}

extension RestoreBinanceViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.descriptionRow(
                                id: "description",
                                text: "restore.binance.description".localized,
                                font: .subhead2,
                                textColor: .themeGray,
                                ignoreBottomMargin: true
                        )
                    ]
            ),
            Section(
                    id: "api-key",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: apiKeyCell,
                                id: "api-key",
                                dynamicHeight: { [weak self] width in
                                    self?.apiKeyCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),
            Section(
                    id: "secret-key",
                    headerState: .margin(height: .margin16),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: secretKeyCell,
                                id: "secret-key",
                                dynamicHeight: { [weak self] width in
                                    self?.secretKeyCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )
        ]
    }

}

extension RestoreBinanceViewController: IScanQrViewControllerDelegate {

    func didFetch(string: String) {
        viewModel.onFetch(qrCodeString: string)
    }

}
