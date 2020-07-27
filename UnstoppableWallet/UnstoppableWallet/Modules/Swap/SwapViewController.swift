import UIKit
import ThemeKit

class SwapViewController: ThemeViewController {
    private let delegate: ISwapViewDelegate

    private let scrollView = UIScrollView()
    private let container = UIView()

    private let iconImageView = UIImageView()

    private let topLineView = UIView()
    private let fromTitleLabel = UILabel()
    private let fromBadgeView = BadgeView()
    private let fromInputView = SwapInputView()
    private let fromAvailableBalanceView = SwapValueView()

    private let separatorLineView = UIView()

    private let toTitleLabel = UILabel()
    private let toBadgeView = BadgeView()
    private let toInputView = SwapInputView()
    private let toPriceView = SwapValueView()
    private let toPriceImpactView = SwapValueView()
    private let minMaxView = SwapValueView()

    private let swapButton = ThemeButton()

    init(delegate: ISwapViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.title".localized
        view.backgroundColor = .themeDarker

        view.addSubview(scrollView)
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .onDrag
        scrollView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        scrollView.addSubview(container)
        container.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(self.view)
            maker.top.bottom.equalTo(self.scrollView)
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Info Icon Small")?.tinted(with: .themeJacob), style: .plain, target: self, action: #selector(onInfo))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onClose))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        initLayout()
        delegate.onViewDidLoad()
    }

    func initLayout() {
        fromInputView.delegate = self
        toInputView.delegate = self

        container.addSubview(topLineView)
        container.addSubview(fromTitleLabel)
        container.addSubview(fromBadgeView)
        container.addSubview(fromInputView)
        container.addSubview(fromAvailableBalanceView)
        container.addSubview(separatorLineView)
        container.addSubview(toTitleLabel)
        container.addSubview(toBadgeView)
        container.addSubview(toInputView)
        container.addSubview(toPriceView)
        container.addSubview(toPriceImpactView)
        container.addSubview(minMaxView)
        container.addSubview(swapButton)

        topLineView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }
        topLineView.backgroundColor = .themeSteel20

        fromTitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(topLineView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
        }
        fromTitleLabel.font = .body
        fromTitleLabel.textColor = .themeOz
        fromTitleLabel.text = "swap.you_pay".localized

        fromBadgeView.snp.makeConstraints { maker in
            maker.centerY.equalTo(fromTitleLabel)
            maker.leading.equalTo(fromTitleLabel.snp.trailing).offset(CGFloat.margin2x)
        }
        fromBadgeView.set(text: "swap.estimated".localized)

        fromInputView.snp.makeConstraints { maker in
            maker.top.equalTo(fromTitleLabel.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }
        fromInputView.set(maxButtonVisible: false)

        fromAvailableBalanceView.snp.makeConstraints { maker in
            maker.top.equalTo(fromInputView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        separatorLineView.snp.makeConstraints { maker in
            maker.top.equalTo(fromAvailableBalanceView.snp.bottom).offset(CGFloat.margin2x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOneDp)
        }
        separatorLineView.backgroundColor = .themeSteel20

        toTitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(separatorLineView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().inset(CGFloat.margin4x)
        }
        toTitleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        toTitleLabel.font = .body
        toTitleLabel.textColor = .themeOz
        toTitleLabel.text = "swap.you_get".localized

        toBadgeView.snp.makeConstraints { maker in
            maker.centerY.equalTo(toTitleLabel)
            maker.leading.equalTo(toTitleLabel.snp.trailing).offset(CGFloat.margin2x)
        }
        toBadgeView.set(text: "estimated".localized)

        toInputView.snp.makeConstraints { maker in
            maker.top.equalTo(toTitleLabel.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }
        toInputView.set(maxButtonVisible: false)

        toPriceView.snp.makeConstraints { maker in
            maker.top.equalTo(toInputView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        toPriceImpactView.snp.makeConstraints { maker in
            maker.top.equalTo(toPriceView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        minMaxView.snp.makeConstraints { maker in
            maker.top.equalTo(toPriceImpactView.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
        }

        swapButton.snp.makeConstraints { maker in
            maker.top.equalTo(minMaxView.snp.bottom).offset(CGFloat.margin3x + CGFloat.margin4x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(50)
        }

        swapButton.apply(style: .primaryYellow)
        swapButton.setTitle("swap.proceed".localized, for: .normal)
        swapButton.addTarget(self, action: #selector(onSwapTouchUp), for: .touchUpInside)

        fromAvailableBalanceView.set(title: "swap.balance".localized)

        toPriceView.set(title: "swap.price".localized)
        toPriceImpactView.set(title: "swap.price_impact".localized)
    }

    private func set(estimatedField: SwapPath) {
        fromBadgeView.isHidden = estimatedField == .to
        toBadgeView.isHidden = estimatedField == .from
    }

    private func path(for view: SwapInputView) -> SwapPath {
        view == fromInputView ? .from : .to
    }


    @objc func onClose() {
        delegate.onClose()
    }

    @objc func onInfo() {
    }

    @objc func onSwapTouchUp() {
        delegate.onClose()
    }

}

extension SwapViewController: ISwapView {

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func bind(viewItem: SwapViewItem) {
        set(estimatedField: viewItem.estimatedField)

        fromInputView.set(tokenName: viewItem.tokenIn)
        toInputView.set(tokenName: viewItem.tokenOut)

        switch viewItem.estimatedField {
        case .to: toInputView.set(text: viewItem.estimatedAmount)
        case .from: fromInputView.set(text: viewItem.estimatedAmount)
        }

        fromAvailableBalanceView.set(value: viewItem.availableBalance)

        minMaxView.set(title: viewItem.minMaxTitle)
        minMaxView.set(value: viewItem.minMaxValue)

        toPriceView.set(value: viewItem.executionPriceValue)
        toPriceImpactView.set(value: viewItem.priceImpactValue)
        toPriceImpactView.set(color: viewItem.priceImpactColor)

        swapButton.isEnabled = viewItem.swapButtonEnabled
    }

    func amount(path: SwapPath) -> String? {
        switch path {
        case .to: return toInputView.text
        case .from: return fromInputView.text
        }
    }

}

extension SwapViewController: ISwapInputViewDelegate {

    func isValid(_ inputView: SwapInputView, text: String) -> Bool {
        true
    }

    func willChangeAmount(_ inputView: SwapInputView, text: String?) {
        print("willChangeAmount - ", path(for: inputView), " - ", text)
    }

    func didChangeAmount(_ inputView: SwapInputView, text: String?) {
        delegate.didChangeAmount(path: path(for: inputView))

        print("didChangeAmount - ", path(for: inputView))
    }

    func onMaxClicked(_ inputView: SwapInputView) {
        print("onMaxClicked - ", path(for: inputView))
    }

    func onTokenSelectClicked(_ inputView: SwapInputView) {
        delegate.onTokenSelect(path: path(for: inputView))
    }

}