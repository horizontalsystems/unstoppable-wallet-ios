import UIKit
import ThemeKit
import UniswapKit
import HUD
import RxSwift
import RxCocoa

class SwapViewController: ThemeViewController {
    private static let levelColors: [UIColor] = [.themeGray, .themeRemus, .themeJacob, .themeLucian]
    private static let spinnerRadius: CGFloat = 8
    private static let spinnerLineWidth: CGFloat = 2

    private static let processTag = 0, approveTag = 1, approvingTag = 2

    private let disposeBag = DisposeBag()

    private let viewModel: SwapViewModel

    private let scrollView = UIScrollView()
    private let container = UIView()

    private let fromCoinCard: SwapCoinCard
    private let toCoinCard: SwapCoinCard

    private let loadingSpinner = HUDProgressView(
            strokeLineWidth: SwapViewController.spinnerLineWidth,
            radius: SwapViewController.spinnerRadius,
            strokeColor: .themeOz
    )
    private let priceLabel = UILabel()
    private let switchButton = UIButton()

    private let allowanceView: SwapAllowanceView

    private let swapAreaWrapper = UIView()
    private let priceImpactView = AdditionalDataView()
    private let minMaxView = AdditionalDataView()
    private let separatorView = UIView()
    private let settingsView = SettingsDisclosureView()

    private let button = ThemeButton()

    private let swapErrorLabel = UILabel()
    private let validationErrorLabel = UILabel()

    init(viewModel: SwapViewModel) {
        self.viewModel = viewModel

        fromCoinCard = SwapCoinCard(viewModel: viewModel.fromInputPresenter)
        toCoinCard = SwapCoinCard(viewModel: viewModel.toInputPresenter)
        allowanceView = SwapAllowanceView(viewModel: viewModel.allowancePresenter)

        super.init()

        fromCoinCard.presentDelegate = self
        toCoinCard.presentDelegate = self

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "guides.title".localized

        title = "swap.title".localized
        view.backgroundColor = .themeDarker

        view.addSubview(scrollView)

        scrollView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag

        scrollView.addSubview(container)
        container.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(self.view)
            maker.top.bottom.equalTo(self.scrollView)
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Info Icon Medium")?.tinted(with: .themeJacob), style: .plain, target: self, action: #selector(onInfo))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        initLayout()
        subscribeToViewModel()
    }

    private func initLayout() {
        container.addSubview(fromCoinCard)
        fromCoinCard.snp.makeConstraints { maker in
            maker.top.equalToSuperview()//.offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        container.addSubview(loadingSpinner)
        loadingSpinner.snp.makeConstraints { maker in
            maker.top.equalTo(fromCoinCard.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
            maker.width.height.equalTo(SwapViewController.spinnerRadius * 2 + SwapViewController.spinnerLineWidth)
        }

        loadingSpinner.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        loadingSpinner.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        loadingSpinner.isHidden = false

        container.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(loadingSpinner)
            maker.leading.equalTo(loadingSpinner.snp.trailing).offset(CGFloat.margin2x)
        }

        priceLabel.font = .subhead2
        priceLabel.textAlignment = .center
        set(price: nil)

        container.addSubview(switchButton)
        switchButton.snp.makeConstraints { maker in
            maker.top.equalTo(fromCoinCard.snp.bottom)
            maker.leading.equalTo(priceLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalTo(loadingSpinner).offset(CGFloat.margin3x)
        }

        switchButton.setImage(UIImage(named: "Swap Switch Icon")?.tinted(with: .themeGray), for: .normal)
        switchButton.addTarget(self, action: #selector(onSwitchTap), for: .touchUpInside)
        switchButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        switchButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        container.addSubview(toCoinCard)
        toCoinCard.snp.makeConstraints { maker in
            maker.top.equalTo(loadingSpinner.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        container.addSubview(allowanceView)
        allowanceView.snp.makeConstraints {maker in
            maker.top.equalTo(toCoinCard.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }


        container.addSubview(swapAreaWrapper)
        swapAreaWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(allowanceView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        swapAreaWrapper.isHidden = true

        swapAreaWrapper.addSubview(priceImpactView)
        priceImpactView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }

        swapAreaWrapper.addSubview(minMaxView)
        minMaxView.snp.makeConstraints { maker in
            maker.top.equalTo(priceImpactView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
        }

        swapAreaWrapper.addSubview(validationErrorLabel)
        validationErrorLabel.snp.makeConstraints { maker in
            maker.top.equalTo(minMaxView.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        validationErrorLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        validationErrorLabel.font = .subhead2
        validationErrorLabel.textColor = .themeLucian
        validationErrorLabel.numberOfLines = 0

        swapAreaWrapper.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.top.equalTo(validationErrorLabel.snp.bottom)
            maker.height.equalTo(CGFloat.heightOnePixel)
            maker.leading.trailing.equalToSuperview()
        }

        separatorView.backgroundColor = .themeSteel20

        swapAreaWrapper.addSubview(settingsView)
        settingsView.snp.makeConstraints { maker in
            maker.top.equalTo(separatorView)
            maker.height.equalTo(CGFloat.heightSingleLineCell)
            maker.leading.trailing.equalToSuperview()
        }

        settingsView.set(title: "swap.advanced_settings".localized)
        settingsView.onTouchUp = { [weak self] in
            self?.onSettingsButtonTouchUp()
        }

        swapAreaWrapper.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.top.equalTo(settingsView.snp.bottom).offset(CGFloat.margin4x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButton)
        }

        button.addTarget(self, action: #selector(onButtonTouchUp), for: .touchUpInside)
        button.apply(style: .primaryYellow)
        button.setTitle("swap.proceed_button".localized, for: .normal)
        button.isEnabled = false

        container.addSubview(swapErrorLabel)
        swapErrorLabel.snp.makeConstraints { maker in
            maker.top.equalTo(allowanceView.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        swapErrorLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        swapErrorLabel.font = .subhead2
        swapErrorLabel.textColor = .themeLucian
        swapErrorLabel.numberOfLines = 0

        fromCoinCard.viewDidLoad()
        toCoinCard.viewDidLoad()
        allowanceView.viewDidLoad()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.isLoading) { [weak self] in self?.set(loading: $0) }
        subscribe(disposeBag, viewModel.swapError) { [weak self] in self?.set(swapError: $0) }
        subscribe(disposeBag, viewModel.validationError) { [weak self] in self?.set(validationError: $0) }

        subscribe(disposeBag, viewModel.tradeViewItem) { [weak self] in self?.handle(tradeViewItem: $0) }
        subscribe(disposeBag, viewModel.showProcess) { [weak self] in self?.setButton(tag: SwapViewController.processTag) }
        subscribe(disposeBag, viewModel.showApprove) { [weak self] in self?.setButton(tag: SwapViewController.approveTag) }
        subscribe(disposeBag, viewModel.showApproving) { [weak self] in self?.setButton(tag: SwapViewController.approvingTag) }
        subscribe(disposeBag, viewModel.isActionEnabled) { [weak self] in self?.button.isEnabled = $0 }
        subscribe(disposeBag, viewModel.isTradeDataHidden) { [weak self] in self?.set(swapDataHidden: $0) }

        subscribe(disposeBag, viewModel.openApprove) { [weak self] in self?.openApprove(data: $0) }
        subscribe(disposeBag, viewModel.openConfirmation) { [weak self] in self?.openConfirmation() }
        subscribe(disposeBag, viewModel.close) { [weak self] in self?.onClose() }
    }

    @objc func onClose() {
        dismiss(animated: true)
    }

    @objc func onInfo() {
        let module = UniswapInfoRouter.module()
        present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    @objc func onSwitchTap() {
        viewModel.onTapSwitch()
    }

    @objc func onSettingsButtonTouchUp() {
        let viewController = SwapTradeOptionsView(viewModel: viewModel.tradeOptionsViewModel)
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    @objc func onButtonTouchUp() {
        switch button.tag {
        case SwapViewController.approveTag: viewModel.onTapApprove()
        case SwapViewController.processTag: openConfirmation()
        default: ()
        }
    }

    private func set(loading: Bool) {
        loadingSpinner.isHidden = !loading
        if loading {
            loadingSpinner.startAnimating()
        } else {
            loadingSpinner.stopAnimating()
        }
    }

    private func set(price: String?) {
        guard let price = price else {
            priceLabel.textColor = .themeGray50
            priceLabel.text = "swap.price".localized
            return
        }
        priceLabel.textColor = .themeGray
        priceLabel.text = price
    }

}

extension SwapViewController {

    private func set(swapError: String?) {
        swapErrorLabel.text = swapError
    }

    private func set(validationError: String?) {
        validationErrorLabel.text = validationError
        separatorView.snp.updateConstraints { maker in
            maker.top.equalTo(validationErrorLabel.snp.bottom).offset(validationError == nil ? 0 : CGFloat.margin3x)
        }
        view.layoutIfNeeded()
    }

    private func color(for level: SwapModule.PriceImpactLevel) -> UIColor {
        let index = level.rawValue % SwapViewController.levelColors.count
        return SwapViewController.levelColors[index]
    }

    private func handle(tradeViewItem: SwapModule.TradeViewItem?) {
        set(price: tradeViewItem?.executionPrice)

        guard let viewItem = tradeViewItem else {
            priceImpactView.clear()
            minMaxView.clear()

            return
        }

        priceImpactView.bind(title: "swap.price_impact".localized, value: viewItem.priceImpact?.localized)
        priceImpactView.setValue(color: color(for: viewItem.priceImpactLevel))

        minMaxView.bind(title: viewItem.minMaxTitle?.localized, value: viewItem.minMaxAmount?.localized)
    }

    private func setButton(tag: Int) {
        button.tag = tag

        switch tag {
        case SwapViewController.approveTag: button.setTitle("button.approve".localized, for: .normal)
        case SwapViewController.approvingTag: button.setTitle("swap.approving_button".localized, for: .normal)
        default: button.setTitle("swap.proceed_button".localized, for: .normal)
        }
    }

    private func set(swapDataHidden: Bool) {
        swapAreaWrapper.isHidden = swapDataHidden
    }

    private func openApprove(data: SwapModule.ApproveData?) {
//        guard let data = data,
//              let vc = SwapApproveModule.instance(data: data, delegate: self) else {
//            return
//        }
//
//        self.present(vc, animated: true)
    }

    private func openConfirmation() {
    }

}

extension SwapViewController: IPresentDelegate {

    func show(viewController: UIViewController) {
        present(viewController, animated: true)
    }

}

extension SwapViewController: ISwapApproveDelegate {

    func didApprove() {
        viewModel.didApprove()
    }

}
