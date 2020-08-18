import UIKit
import ActionSheet
import ThemeKit
import RxSwift

class SwapApproveViewController: ThemeActionSheetController {
    private let disposeBag = DisposeBag()

    private let delegate: ISwapApproveViewDelegate

    private let titleView = BottomSheetTitleView()
    private let amountView = SwapApproveAmountView()
    private let separatorView = UIView()
    private let feeView = AdditionalDataWithLoadingView()
    private let transactionSpeedView = AdditionalDataView()
    private let approveButton = ThemeButton()

    init(delegate: ISwapApproveViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.onTapClose = { [weak self] in
            self?.delegate.onTapClose()
        }

        view.addSubview(amountView)
        amountView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
            maker.height.equalTo(72)
        }

        view.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountView.snp.bottom)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        view.addSubview(feeView)
        feeView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(separatorView.snp.bottom).offset(CGFloat.margin3x)
        }

        view.addSubview(transactionSpeedView)
        transactionSpeedView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(feeView.snp.bottom)
        }


        view.addSubview(approveButton)
        approveButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(transactionSpeedView.snp.bottom).offset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
        }

        approveButton.apply(style: .primaryYellow)
        approveButton.setTitle("swap.approve_button".localized, for: .normal)
        approveButton.addTarget(self, action: #selector(onTapApprove), for: .touchUpInside)

        delegate.onLoad()
    }

    @objc private func onTapApprove() {
        delegate.onTapApprove()
    }

}

extension SwapApproveViewController: ISwapApproveView {

    func set(viewItem: SwapApproveModule.ViewItem) {
        titleView.bind(
                title: "swap.approve.title".localized,
                subtitle: "swap.approve.subtitle".localized,
                image: UIImage(named: "Swap Icon Medium")?.tinted(with: .themeGray))

        amountView.bind(amount: viewItem.amount, description: viewItem.coinCode)

        approveButton.isEnabled = false
        switch viewItem.fee {
        case .loading:
            feeView.set(loading: true)
        case .completed(let feeValue):
            feeView.bind(title: "swap.fee".localized, value: feeValue)
            approveButton.isEnabled = true
        default: ()
        }

        transactionSpeedView.bind(title: "swap.transaction_speed".localized, value: viewItem.transactionSpeed)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.smartDescription)
    }

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

}
