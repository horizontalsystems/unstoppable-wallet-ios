import UIKit
import ActionSheet
import ThemeKit
import RxSwift

class SwapApproveViewController: ThemeActionSheetController {
    private let disposeBag = DisposeBag()

    private let viewModel: SwapApproveViewModel
    private let delegate: ISwapApproveDelegate

    private let titleView = BottomSheetTitleView()
    private let amountView = SwapApproveAmountView()
    private let separatorView = UIView()
    private let feeView = AdditionalDataWithLoadingView()
    private let transactionSpeedView = AdditionalDataView()
    private let approveButton = ThemeButton()

    init(viewModel: SwapApproveViewModel, delegate: ISwapApproveDelegate) {
        self.viewModel = viewModel
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
            self?.dismiss(animated: true)
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

        subscribeToViewModel()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.approveSuccess) { [weak self] success in
            guard success else {
                return
            }

            HudHelper.instance.showSuccess()
            self?.delegate.didApprove()
            self?.dismiss(animated: true)
        }

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] viewItem in self?.set(viewItem: viewItem) }
        subscribe(disposeBag, viewModel.feeLoading) { [weak self] feeLoading in self?.set(feeLoading: feeLoading) }
        subscribe(disposeBag, viewModel.fee) { [weak self] fee in fee.flatMap { self?.set(fee: $0) } }
    }

    @objc private func onTapApprove() {
        viewModel.onTapApprove()
    }

}

extension SwapApproveViewController {

    private func set(feeLoading: Bool) {
        approveButton.isEnabled = !feeLoading
        feeView.set(loading: feeLoading)
    }

    private func set(fee: String) {
        feeView.bind(title: "swap.fee".localized, value: fee)
        approveButton.isEnabled = true
    }

    private func set(viewItem: SwapApproveModule.ViewItem) {
        titleView.bind(
                title: "swap.approve.title".localized,
                subtitle: "swap.approve.subtitle".localized,
                image: UIImage(named: "Swap Icon Medium")?.tinted(with: .themeGray))

        amountView.bind(amount: viewItem.amount, description: viewItem.coinCode)
        transactionSpeedView.bind(title: "swap.transactions_speed".localized, value: viewItem.transactionSpeed)
    }

    private func show(error: Error) {
        HudHelper.instance.showError(title: error.smartDescription)
    }

}
