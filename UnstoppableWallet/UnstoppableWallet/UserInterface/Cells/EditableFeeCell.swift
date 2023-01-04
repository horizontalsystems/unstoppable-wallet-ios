import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

protocol IEditableFeeViewModel: IFeeViewModel {
    var editButtonVisibleDriver: Driver<Bool> { get }
    var editButtonHighlightedDriver: Driver<Bool> { get }
}

class EditableFeeCell: BaseSelectableThemeCell {
    private let disposeBag = DisposeBag()

    private let viewModel: IEditableFeeViewModel

    private var value: FeeCell.Value?
    private var imageVisible: Bool = true
    private var imageHighlighted: Bool = false
    private var spinnerVisible: Bool = false

    init(viewModel: IEditableFeeViewModel, isFirst: Bool = true, isLast: Bool = true) {
        self.viewModel = viewModel
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true
        set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

        sync()
        subscribe(disposeBag, viewModel.valueDriver) { [weak self] value in
            self?.value = value
            self?.sync()
        }
        subscribe(disposeBag, viewModel.editButtonVisibleDriver) { [weak self] visible in
            self?.imageVisible = visible
            self?.selectionStyle = visible ? .default : .none
            self?.sync()
        }
        subscribe(disposeBag, viewModel.editButtonHighlightedDriver) { [weak self] highlighted in
            self?.imageHighlighted = highlighted
            self?.sync()
        }
        subscribe(disposeBag, viewModel.spinnerVisibleDriver) { [weak self] visible in
            self?.spinnerVisible = visible
            self?.sync()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sync(value: FeeCell.Value? = nil) {
        CellBuilderNew.buildStatic(cell: self, rootElement:
            .hStack([
                .text { (component: TextComponent) -> () in
                    component.font = .subhead2
                    component.textColor = .themeGray
                    component.text = "send.fee".localized
                },
                .text { [weak self] (component: TextComponent) -> () in
                    if let value = self?.value {
                        component.isHidden = false
                        component.font = .subhead1
                        component.textColor = value.type.textColor
                        component.text = value.text
                    } else {
                        component.isHidden = true
                    }
                },
                .margin8,
                .image20 { [weak self] (component: ImageComponent) -> () in
                    component.imageView.image =  UIImage(named: "edit2_20")?.withRenderingMode(.alwaysTemplate)

                    component.isHidden = !(self?.imageVisible ?? false)
                    component.imageView.tintColor = (self?.imageHighlighted ?? false) ? .themeJacob : .themeGray

                },
                .spinner20 { [weak self] (component: SpinnerComponent) -> () in
                        component.isHidden = !(self?.spinnerVisible ?? false)
                }
            ])
        )
    }

}
