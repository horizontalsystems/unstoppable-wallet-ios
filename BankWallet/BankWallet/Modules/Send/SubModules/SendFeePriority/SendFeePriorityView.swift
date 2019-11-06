import UIKit
import SnapKit
import UIExtensions

class SendFeePriorityView: UIView {
    let delegate: ISendFeePriorityViewDelegate
    let selectableValueView = SelectableValueView(title: "send.tx_speed".localized)

    init(delegate: ISendFeePriorityViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)

        selectableValueView.delegate = self
        selectableValueView.set(value: delegate.feeRatePriority.title)

        snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.feePriorityHeight)
        }

        addSubview(selectableValueView)
        selectableValueView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(SendTheme.feePriorityTopMargin)
            maker.leading.trailing.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

}

extension SendFeePriorityView: ISendFeePriorityView {

    func setPriority() {
        selectableValueView.set(value: delegate.feeRatePriority.title)
    }

}

extension SendFeePriorityView: ISelectableValueViewDelegate {

    func onSelectorTap() {
        self.delegate.onFeePrioritySelectorTap()
    }

}
