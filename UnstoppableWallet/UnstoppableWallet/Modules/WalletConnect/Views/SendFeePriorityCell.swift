import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit

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
    var warningOfStuckDriver: Driver<Bool> { get }
    func openSelectPriority()
    func selectPriority(index: Int)
    func changeCustomPriority(value: Int)
}

protocol ISendFeePriorityCellDelegate: IDynamicHeightCellDelegate {
    func open(viewController: UIViewController)
}

protocol IDynamicHeightCellDelegate: AnyObject {
    func onChangeHeight()
}

class SendFeePriorityCell: UITableViewCell {
    static private let warningOfStuckString = "send.stuck_warning".localized
    weak var delegate: ISendFeePriorityCellDelegate?

    private let viewModel: ISendFeePriorityViewModel
    private let separator = UIView()
    private let selectableValueView = C5Cell(style: .default, reuseIdentifier: nil)

    private let feeSliderWrapper = FeeSliderWrapper()
    private let warningOfStuckView = HighlightedDescriptionView()

    private let disposeBag = DisposeBag()

    var isVisible = true

    init(viewModel: ISendFeePriorityViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separator.backgroundColor = .themeSteel20

        contentView.addSubview(selectableValueView.contentView)
        selectableValueView.contentView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }

        selectableValueView.title = "send.tx_speed".localized
        selectableValueView.titleImage = UIImage(named: "circle_information_20")?.withTintColor(.themeJacob)
        selectableValueView.titleImageAction = { [weak self] in
            self?.openFeeInfo()
        }
       selectableValueView.valueAction = { [weak self] in
            self?.viewModel.openSelectPriority()
        }

        contentView.addSubview(feeSliderWrapper)
        feeSliderWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(selectableValueView.contentView.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        feeSliderWrapper.finishTracking = { [weak self] value in
            self?.finishTracking(value: value)
        }

        contentView.addSubview(warningOfStuckView)
        warningOfStuckView.snp.makeConstraints { maker in
            maker.top.equalTo(feeSliderWrapper.snp.bottom).offset(CGFloat.margin16 + .margin12)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        warningOfStuckView.text = Self.warningOfStuckString

        subscribe(disposeBag, viewModel.priorityDriver) { [weak self] priority in self?.selectableValueView.value = priority }
        subscribe(disposeBag, viewModel.openSelectPrioritySignal) { [weak self] viewItems in self?.openSelectPriority(viewItems: viewItems) }
        subscribe(disposeBag, viewModel.warningOfStuckDriver) { [weak self] in self?.show(warningOfStuck: $0) }
        subscribe(disposeBag, viewModel.feeSliderDriver) { [weak self] viewItem in
                    if let viewItem = viewItem {
                        self?.feeSliderWrapper.set(value: viewItem.initialValue, range: viewItem.range, description: viewItem.unit)
                        self?.feeSliderWrapper.isHidden = false
                    } else {
                        self?.feeSliderWrapper.isHidden = true
                    }

                    self?.delegate?.onChangeHeight()
                }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func openFeeInfo() {
        let infoController = InfoModule.viewController(dataSource: FeeInfoDataSource())
        delegate?.open(viewController: ThemeNavigationController(rootViewController: infoController))
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


    private func finishTracking(value: Int) {
        viewModel.changeCustomPriority(value: value)
    }

    private func show(warningOfStuck: Bool) {
        warningOfStuckView.isHidden = !warningOfStuck

        delegate?.onChangeHeight()
    }

}

extension SendFeePriorityCell {

    var cellHeight: CGFloat {
        let feeSliderHeight: CGFloat = feeSliderWrapper.isHidden ? 0 : 29
        let warningOfStuckHeight = warningOfStuckView.isHidden ? 0 : (HighlightedDescriptionView.height(containerWidth: warningOfStuckView.width, text: Self.warningOfStuckString) + .margin16 + .margin12)

        return isVisible ? (CGFloat.heightSingleLineCell + feeSliderHeight + warningOfStuckHeight) : 0
    }

}
