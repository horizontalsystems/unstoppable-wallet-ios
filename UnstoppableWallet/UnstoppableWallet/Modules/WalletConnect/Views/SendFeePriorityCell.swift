import UIKit
import SnapKit
import RxSwift
import RxCocoa

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

protocol ISendFeePriorityCellDelegate: IDynamicHeightCellDelegate {
    func open(viewController: UIViewController)
}

protocol IDynamicHeightCellDelegate: AnyObject {
    func onChangeHeight()
}

class SendFeePriorityCell: UITableViewCell {
    weak var delegate: ISendFeePriorityCellDelegate?

    private let viewModel: ISendFeePriorityViewModel
    private let selectableValueView = SelectableValueView(title: "send.tx_speed".localized)

    private let feeSliderWrapper = FeeSliderWrapper()

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
                        self?.feeSliderWrapper.set(value: viewItem.initialValue, range: viewItem.range, description: viewItem.unit)
                        self?.feeSliderWrapper.isHidden = false
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


    private func finishTracking(value: Int) {
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
