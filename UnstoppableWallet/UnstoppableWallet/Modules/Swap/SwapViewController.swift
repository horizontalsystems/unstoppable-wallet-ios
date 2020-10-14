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

    private let processSpinner = HUDProgressView(
            strokeLineWidth: SwapViewController.spinnerLineWidth,
            radius: SwapViewController.spinnerRadius,
            strokeColor: .themeOz
    )

    private let disposeBag = DisposeBag()

    private let viewModel: SwapViewModel

    private let scrollView = UIScrollView()
    private let container = UIView()

    private let topLineView = UIView()

    private let fromInputView: SwapInputView

    private let fromBalanceView = AdditionalDataWithErrorView()
    private let allowanceView: SwapAllowanceView

    private let separatorLineView = UIView()

    private let toInputView: SwapInputView

    private let swapAreaWrapper = UIView()
    private let priceView = AdditionalDataView()
    private let priceImpactView = AdditionalDataView()
    private let minMaxView = AdditionalDataView()

    private let button = ThemeButton()

    private let swapErrorLabel = UILabel()

    init(viewModel: SwapViewModel) {
        self.viewModel = viewModel

        fromInputView = SwapInputView(presenter: viewModel.fromInputPresenter)
        toInputView = SwapInputView(presenter: viewModel.toInputPresenter)
        allowanceView = SwapAllowanceView(presenter: viewModel.allowancePresenter)

        super.init()

        fromInputView.presentDelegate = self
        toInputView.presentDelegate = self

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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onClose))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        initLayout()
        subscribeToViewModel()
    }

    private func initLayout() {
        container.addSubview(topLineView)
        container.addSubview(processSpinner)

        container.addSubview(fromInputView)
        container.addSubview(fromBalanceView)
        container.addSubview(allowanceView)
        container.addSubview(separatorLineView)
        container.addSubview(toInputView)

        container.addSubview(swapAreaWrapper)
        swapAreaWrapper.addSubview(priceView)
        swapAreaWrapper.addSubview(priceImpactView)
        swapAreaWrapper.addSubview(minMaxView)
        swapAreaWrapper.addSubview(button)

        container.addSubview(swapErrorLabel)

        topLineView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        topLineView.backgroundColor = .themeSteel20

        processSpinner.snp.makeConstraints { maker in
            maker.top.equalTo(topLineView.snp.bottom).offset(CGFloat.margin3x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.width.height.equalTo(SwapViewController.spinnerRadius * 2 + SwapViewController.spinnerLineWidth)
        }
        processSpinner.isHidden = true

        fromInputView.snp.makeConstraints { maker in
            maker.top.equalTo(topLineView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        fromBalanceView.snp.makeConstraints { maker in
            maker.top.equalTo(fromInputView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        allowanceView.snp.makeConstraints {maker in
            maker.top.equalTo(fromBalanceView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
        }

        separatorLineView.snp.makeConstraints { maker in
            maker.top.equalTo(allowanceView.snp.bottom).offset(CGFloat.margin1x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorLineView.backgroundColor = .themeSteel20

        toInputView.snp.makeConstraints { maker in
            maker.top.equalTo(separatorLineView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        swapAreaWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(toInputView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        swapAreaWrapper.isHidden = true

        priceView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        priceImpactView.snp.makeConstraints { maker in
            maker.top.equalTo(priceView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
        }

        minMaxView.snp.makeConstraints { maker in
            maker.top.equalTo(priceImpactView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
        }

        button.snp.makeConstraints { maker in
            maker.top.equalTo(minMaxView.snp.bottom).offset(CGFloat.margin4x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(50)
        }

        button.addTarget(self, action: #selector(onButtonTouchUp), for: .touchUpInside)
        button.apply(style: .primaryYellow)
        button.setTitle("swap.proceed_button".localized, for: .normal)
        button.isEnabled = false

        swapErrorLabel.snp.makeConstraints { maker in
            maker.top.equalTo(toInputView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        swapErrorLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        swapErrorLabel.font = .caption
        swapErrorLabel.textColor = .themeLucian
        swapErrorLabel.numberOfLines = 0
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.isLoading) { [weak self] in self?.set(loading: $0) }
        subscribe(disposeBag, viewModel.swapError) { [weak self] in self?.set(swapError: $0) }

        subscribe(disposeBag, viewModel.balance) { [weak self] in self?.set(fromBalance: $0) }
        subscribe(disposeBag, viewModel.balanceError) { [weak self] in self?.set(error: $0) }

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

    @objc func onButtonTouchUp() {
        switch button.tag {
        case SwapViewController.approveTag: viewModel.onTapApprove()
        case SwapViewController.processTag: viewModel.onTapProceed()
        default: ()
        }
    }

    private func set(loading: Bool) {
        processSpinner.isHidden = !loading
        if loading {
            processSpinner.startAnimating()
        } else {
            processSpinner.stopAnimating()
        }
    }

}

extension SwapViewController {

    private func set(swapError: String?) {
        swapErrorLabel.text = swapError
    }

    private func set(fromBalance: String?) {
        fromBalanceView.bind(title: "swap.balance".localized, value: fromBalance)
    }

    private func set(error: String?) {
        fromBalanceView.bind(error: error)
    }

    private func color(for level: SwapModule.PriceImpactLevel) -> UIColor {
        let index = level.rawValue % SwapViewController.levelColors.count
        return SwapViewController.levelColors[index]
    }

    private func handle(tradeViewItem: SwapModule.TradeViewItem?) {
        // todo: hide/show when nil/not nil
        guard let viewItem = tradeViewItem else {
            return
        }

        priceView.bind(title: "swap.price".localized, value: viewItem.executionPrice?.localized)

        priceImpactView.bind(title: "swap.price_impact".localized, value: viewItem.priceImpact?.localized)
        priceImpactView.setValue(customColor: color(for: viewItem.priceImpactLevel))

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
        guard let data = data,
              let vc = SwapApproveModule.instance(coin: data.coin, spenderAddress: data.spenderAddress, amount: data.amount, delegate: self) else {
            return
        }

        present(vc, animated: true)
    }

    private func openConfirmation() {
        let vc = SwapConfirmationView(presenter: viewModel.confirmationPresenter, delegate: self)
        navigationController?.pushViewController(vc, animated: true)
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

extension SwapViewController: ISwapConfirmationDelegate {

    func onSwap() {
        viewModel.onSwap()
    }

    func onCancel() {
        navigationController?.popViewController(animated: true)
    }

}