import UIKit
import SnapKit
import RxSwift
import RxCocoa

struct SendPriorityViewItem {
    let title: String
    let selected: Bool
}

protocol ISendFeePriorityViewModel {
    var priorityDriver: Driver<String> { get }
    var openSelectPrioritySignal: Signal<[SendPriorityViewItem]> { get }
    func openSelectPriority()
    func selectPriority(index: Int)
}

class SendFeePriorityCell: UITableViewCell {
    weak var viewController: UIViewController?

    private let viewModel: ISendFeePriorityViewModel
    private let selectableValueView = SelectableValueView(title: "send.tx_speed".localized)
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

        viewController?.present(alertController, animated: true)
    }

}

extension SendFeePriorityCell: ISelectableValueViewDelegate {

    func onSelectorTap() {
        viewModel.openSelectPriority()
    }

}
