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
}

protocol ISendFeePriorityCellDelegate: IDynamicHeightCellDelegate {
    func open(viewController: UIViewController)
}

protocol IDynamicHeightCellDelegate: AnyObject {
    func onChangeHeight()
}

class FeeSliderCell: UITableViewCell {
    weak var delegate: ISendFeePriorityCellDelegate?

    private let viewModel: LegacyEvmFeeViewModel
    private let feeSliderWrapper = FeeSliderWrapper()

    private let disposeBag = DisposeBag()

    var isVisible = true

    init(viewModel: LegacyEvmFeeViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(feeSliderWrapper)
        feeSliderWrapper.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        feeSliderWrapper.finishTracking = { [weak self] value in
            self?.finishTracking(value: value)
        }

        subscribe(disposeBag, viewModel.feeSliderDriver) { [weak self] viewItem in
                    if let viewItem = viewItem {
                        self?.feeSliderWrapper.set(value: viewItem.initialValue, range: viewItem.range, description: "gwei")
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

    private func finishTracking(value: Int) {
        viewModel.set(value: value)
    }

}

extension FeeSliderCell {

    var cellHeight: CGFloat {
        29
    }

}
