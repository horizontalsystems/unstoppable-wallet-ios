import UIKit
import ThemeKit
import UniswapKit
import HUD
import RxSwift
import RxCocoa

class Swap2ViewController: ThemeViewController {
    private static let levelColors: [UIColor] = [.themeRemus, .themeJacob, .themeLucian]
    private static let spinnerRadius: CGFloat = 8
    private static let spinnerLineWidth: CGFloat = 2

    private let processSpinner = HUDProgressView(
            strokeLineWidth: Swap2ViewController.spinnerLineWidth,
            radius: Swap2ViewController.spinnerRadius,
            strokeColor: .themeOz
    )

    private let disposeBag = DisposeBag()

    private let viewModel: Swap2ViewModel

    private let scrollView = UIScrollView()
    private let container = UIView()

    private let topLineView = UIView()

    private let fromInputView: Swap2InputView

    private let fromBalanceView = AdditionalDataWithErrorView()
    private let allowanceView = AdditionalDataWithLoadingView()

    private let separatorLineView = UIView()

    private let toInputView: Swap2InputView

    private let swapAreaWrapper = UIView()
    private let priceView = AdditionalDataView()
    private let priceImpactView = AdditionalDataView()
    private let minMaxView = AdditionalDataView()

    private let button = ThemeButton()

    private let swapErrorLabel = UILabel()

    init(viewModel: Swap2ViewModel) {
        self.viewModel = viewModel
        fromInputView = Swap2InputView(presenter: viewModel.fromInputPresenter)
        toInputView = Swap2InputView(presenter: viewModel.toInputPresenter)

        super.init()
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
            maker.width.height.equalTo(Swap2ViewController.spinnerRadius * 2 + Swap2ViewController.spinnerLineWidth)
        }
        processSpinner.isHidden = true

        fromInputView.snp.makeConstraints { maker in
            maker.top.equalTo(topLineView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        fromInputView.set(title: "swap.you_pay".localized)
        fromInputView.setBadge(text: "swap.estimated".localized)
        fromInputView.setBadge(hidden: true)
        fromInputView.set(maxButtonVisible: false)

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

        toInputView.set(title: "swap.you_get".localized)
        toInputView.setBadge(text: "swap.estimated".localized)
        toInputView.setBadge(hidden: false)
        toInputView.set(maxButtonVisible: false)

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

        button.apply(style: .primaryYellow)
        button.addTarget(self, action: #selector(onButtonTouchUp), for: .touchUpInside)

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
        subscribe(disposeBag, viewModel.isSwapDataLoading) { [weak self] in self?.set(loading: $0) }
        subscribe(disposeBag, viewModel.swapDataError) { [weak self] in self?.set(swapDataError: $0) }

        subscribe(disposeBag, viewModel.fromBalance) { [weak self] in self?.set(fromBalance: $0) }
        subscribe(disposeBag, viewModel.balanceError) { [weak self] in self?.set(error: $0) }

        subscribe(disposeBag, viewModel.isAllowanceHidden) { [weak self] in self?.allowanceView.set(hidden: $0) }
        subscribe(disposeBag, viewModel.isAllowanceLoading) { [weak self] in self?.allowanceView.set(loading: $0) }
        subscribe(disposeBag, viewModel.allowance) { [weak self] in self?.set(allowance: $0) }
        subscribe(disposeBag, viewModel.allowanceError) { _ in () } // TODO: show allowanceError

        subscribe(disposeBag, viewModel.tradeViewItem) { [weak self] in self?.set(tradeViewItem: $0) }
        subscribe(disposeBag, viewModel.actionTitle) { [weak self] in self?.button.setTitle($0, for: .normal) }
        subscribe(disposeBag, viewModel.isActionEnabled) { [weak self] in self?.button.isEnabled = $0 }
        subscribe(disposeBag, viewModel.isSwapDataHidden) { [weak self] in self?.set(swapDataHidden: $0) }
    }

    @objc func onClose() {
        dismiss(animated: true)
    }

    @objc func onInfo() {
        let module = UniswapInfoRouter.module()
        present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    @objc func onButtonTouchUp() {
        viewModel.onTapButton()
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

extension Swap2ViewController {

    private func set(fromEstimated: Bool) {
        fromInputView.setBadge(hidden: !fromEstimated)
    }

    private func set(toEstimated: Bool) {
        toInputView.setBadge(hidden: !toEstimated)
    }

    private func set(allowance: Swap2Module.AllowanceViewItem?) {
        guard let item = allowance else {
            return
        }
        allowanceView.bind(title: "swap.allowance".localized, value: item.amount)
        allowanceView.setValue(color: item.isSufficient ? .themeRemus : .themeLucian)
    }

    private func set(swapDataError: Error?) {
        swapErrorLabel.text = swapDataError?.smartDescription
    }

    private func set(fromBalance: String?) {
        fromBalanceView.bind(title: "swap.balance".localized, value: fromBalance)
    }

    private func set(error: Error?) {
        fromBalanceView.bind(error: error?.smartDescription)
    }

    private func color(for level: Swap2Module.PriceImpactLevel) -> UIColor {
        let index = level.rawValue % Swap2ViewController.levelColors.count
        return Swap2ViewController.levelColors[index]
    }

    private func set(tradeViewItem: Swap2Module.TradeViewItem?) {
        // todo: hide/show when nil/not nil
        guard let viewItem = tradeViewItem else {
            return
        }

        priceView.bind(title: "swap.price".localized, value: viewItem.executionPrice?.localized)

        priceImpactView.bind(title: "swap.price_impact".localized, value: viewItem.priceImpact?.localized)
        priceImpactView.setValue(customColor: color(for: viewItem.priceImpactLevel))

        minMaxView.bind(title: viewItem.minMaxTitle?.localized, value: viewItem.minMaxAmount?.localized)
    }

    private func set(swapDataHidden: Bool) {
        swapAreaWrapper.isHidden = swapDataHidden
    }

}

extension Swap2ViewController: ISwapInputViewDelegate {

    func isValid(_ inputView: SwapInputView, text: String) -> Bool {
//        if viewModel.isValid(type: type(for: inputView), text: text) {
            return true
//        } else {
//            inputView.shakeView()
//            return false
//        }
    }

    func willChangeAmount(_ inputView: SwapInputView, text: String?) {
        if inputView == fromInputView {
            viewModel.onChangeFrom(amount: text)
        }
        if inputView == toInputView {
            viewModel.onChangeTo(amount: text)
        }
    }

    func onMaxClicked(_ inputView: SwapInputView) {
    }

    func onTokenSelectClicked(_ inputView: SwapInputView) {
        if inputView == fromInputView {
//
        }
        if inputView == toInputView {
//
        }
    }

}
