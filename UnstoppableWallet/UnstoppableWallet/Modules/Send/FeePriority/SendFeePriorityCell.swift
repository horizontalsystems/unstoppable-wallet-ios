import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

class SendFeePriorityCell: BaseSelectableThemeCell {
    private let disposeBag = DisposeBag()
    private let viewModel: SendFeePriorityViewModel

    weak var sourceViewController: UIViewController?

    init(viewModel: SendFeePriorityViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true

        sync(priority: nil)
        subscribe(disposeBag, viewModel.priorityDriver) { [weak self] priority in
            self?.sync(priority: priority)
        }
    }

    private func sync(priority: String?) {
        CellBuilderNew.buildStatic(cell: self, rootElement: .hStack([
            .text { component in
                component.font = .subhead2
                component.textColor = .themeGray
                component.text = "send.tx_speed".localized
                component.setContentHuggingPriority(.required, for: .horizontal)
            },
            .margin8,
            .image20 { component in
                component.imageView.image = UIImage(named: "circle_information_20")?.withTintColor(.themeGray)
            },
            .margin0,
            .text { _ in },
            .secondaryButton { component in
                component.button.set(style: .default, image: UIImage(named: "arrow_small_down_20"))
                component.button.setTitle(priority, for: .normal)
                component.onTap = { [weak self] in
                    self?.onTapPriority()
                }
            }
        ]))

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
