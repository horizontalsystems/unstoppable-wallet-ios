import UIKit
import SnapKit
import RxSwift
import RxCocoa
import HUD

struct SendPriorityViewItem {
    let title: String
    let selected: Bool
}

struct SendFeeSliderViewItem {
    let initialValue: Int
    let range: ClosedRange<Int>
    let unit: String
}

protocol ISendFeePriorityViewModel {
    var priorityDriver: Driver<String> { get }
    var openSelectPrioritySignal: Signal<[SendPriorityViewItem]> { get }
    var feeSliderDriver: Driver<SendFeeSliderViewItem?> { get }
    func openSelectPriority()
    func selectPriority(index: Int)
    func changeCustomPriority(value: Int)
}

protocol ISendFeePriorityCellDelegate: AnyObject {
    func open(viewController: UIViewController)
    func onChangeHeight()
}

class SendFeePriorityCell: UITableViewCell {
    weak var delegate: ISendFeePriorityCellDelegate?

    private let viewModel: ISendFeePriorityViewModel
    private let selectableValueView = SelectableValueView(title: "send.tx_speed".localized)

    private let feeSliderWrapper = FeeSliderWrapper()
    private let feeRateView = FeeSliderValueView()
    private var sliderLastValue: Int?

    private let disposeBag = DisposeBag()

    init(viewModel: ISendFeePriorityViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(selectableValueView)
        selectableValueView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }
        selectableValueView.delegate = self

        contentView.addSubview(feeSliderWrapper)
        feeSliderWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(selectableValueView.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        feeSliderWrapper.onTracking = { [weak self] value, position in
            self?.onTracking(value, position: position)
        }
        feeSliderWrapper.finishTracking = { [weak self] value in
            self?.finishTracking(value: value)
        }

        viewModel.priorityDriver
                .drive(onNext: { [weak self] priority in
                    self?.selectableValueView.set(value: priority)
                })
                .disposed(by: disposeBag)

        viewModel.openSelectPrioritySignal
                .emit(onNext: { [weak self] viewItems in
                    self?.openSelectPriority(viewItems: viewItems)
                })
                .disposed(by: disposeBag)

        viewModel.feeSliderDriver
                .drive(onNext: { [weak self] viewItem in
                    if let viewItem = viewItem {
                        self?.feeSliderWrapper.set(value: viewItem.initialValue, range: viewItem.range)
                        self?.feeRateView.set(descriptionText: viewItem.unit)
                        self?.feeSliderWrapper.isHidden = false
                        self?.sliderLastValue = viewItem.initialValue
                    } else {
                        self?.feeSliderWrapper.isHidden = true
                    }

                    self?.delegate?.onChangeHeight()
                })
                .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func openSelectPriority(viewItems: [SendPriorityViewItem]) {
        let alertController = AlertRouter.module(
                title: "send.tx_speed".localized,
                viewItems: viewItems.map { viewItem in
                    AlertViewItem(
                            text: viewItem.title,
                            selected: viewItem.selected
                    )
                }
        ) { [weak self] index in
            self?.viewModel.selectPriority(index: index)
        }

        delegate?.open(viewController: alertController)
    }

    private func hudConfig(position: CGPoint) -> HUDConfig {
        var feeConfig = HUDConfig()

        feeConfig.appearStyle = .alphaAppear
        feeConfig.style = .banner(.top)
        feeConfig.absoluteInsetsValue = true
        feeConfig.userInteractionEnabled = true
        feeConfig.hapticType = .none
        feeConfig.blurEffectStyle = nil
        feeConfig.blurEffectIntensity = nil
        feeConfig.borderColor = .themeSteel20
        feeConfig.borderWidth = .heightOnePixel
        feeConfig.exactSize = true
        feeConfig.preferredSize = CGSize(width: 74, height: 48)
        feeConfig.cornerRadius = CGFloat.cornerRadius2x
        feeConfig.handleKeyboard = .none
        feeConfig.inAnimationDuration = 0
        feeConfig.outAnimationDuration = 0

        feeConfig.hudInset = convert(CGPoint(x: position.x - center.x, y: -feeConfig.preferredSize.height - CGFloat.margin2x), to: nil)
        return feeConfig
    }

    private func onTracking(_ value: Int, position: CGPoint) {
        HUD.instance.config = hudConfig(position: position)

        feeRateView.set(value: "\(value)")
        HUD.instance.showHUD(feeRateView)
    }

    private func finishTracking(value: Int) {
        HUD.instance.hide()

        guard sliderLastValue != value else {
            return
        }

        sliderLastValue = value
        viewModel.changeCustomPriority(value: value)
    }

}

extension SendFeePriorityCell {

    var currentHeight: CGFloat {
        feeSliderWrapper.isHidden ? .heightSingleLineCell : 73
    }

}

extension SendFeePriorityCell: ISelectableValueViewDelegate {

    func onSelectorTap() {
        viewModel.openSelectPriority()
    }

}
