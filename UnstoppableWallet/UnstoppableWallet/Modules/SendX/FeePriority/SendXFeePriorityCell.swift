import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

class SendXFeePriorityCell: BaseSelectableThemeCell {
    private let disposeBag = DisposeBag()
    private let viewModel: SendXFeePriorityViewModel

    weak var sourceViewController: UIViewController?

    init(viewModel: SendXFeePriorityViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true
        set(backgroundStyle: .transparent)

        CellBuilder.build(cell: self, elements: [.transparentIconButton, .text, .secondaryButton])

        bind(index: 0, block: { (component: TransparentIconButtonComponent) in
            component.button.set(image: UIImage(named: "circle_information_20"))
            component.onTap = { [weak self] in
                self?.onTapInfo()
            }
        })

        bind(index: 1) { (component: TextComponent) in
            component.set(style: .d1)
            component.text = "send.tx_speed".localized
        }

        subscribe(disposeBag, viewModel.priorityDriver) { [weak self] priority in
            self?.bind(index: 2) { (component: SecondaryButtonComponent) in
                component.button.set(style: .transparent)
                component.button.set(image: UIImage(named: "arrow_small_down_20"))
                component.button.setTitle(priority, for: .normal)
                component.onTap = { [weak self] in
                    self?.onTapPriority()
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func onTapInfo() {
        sourceViewController?.present(InfoModule.feeInfo, animated: true)
    }

    private func onTapPriority() {
        let alertController = AlertRouter.module(
                title: "send.tx_speed".localized,
                viewItems: viewModel.priorityItems
        ) { [weak self] index in
            self?.viewModel.onSelect(index)
        }

        sourceViewController?.present(alertController, animated: true)
    }

}
