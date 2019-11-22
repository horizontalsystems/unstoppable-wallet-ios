import UIKit
import SnapKit
import UIExtensions

class SendFeePriorityView: UIView {
    let delegate: ISendFeePriorityViewDelegate

    private let selectableValueView = SelectableValueView(title: "send.tx_speed".localized)
    private let durationTitleLabel = UILabel()
    private let durationValueLabel = UILabel()

    init(delegate: ISendFeePriorityViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)

        backgroundColor = .clear

        selectableValueView.delegate = self
        selectableValueView.set(value: delegate.feeRatePriority.title)

        addSubview(selectableValueView)
        selectableValueView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
        }

        addSubview(durationTitleLabel)
        durationTitleLabel.text = "send.tx_duration".localized
        durationTitleLabel.font = SendTheme.feeFont
        durationTitleLabel.textColor = SendTheme.feeColor
        durationTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.top.equalTo(selectableValueView.snp.bottom).offset(CGFloat.margin3x)
            maker.bottom.equalToSuperview()
        }

        addSubview(durationValueLabel)
        durationValueLabel.font = SendTheme.feeFont
        durationValueLabel.textColor = SendTheme.feeColor
        durationValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        durationValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(durationTitleLabel.snp.centerY)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.leading.equalTo(durationTitleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.bottom.equalToSuperview()
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

    func set(enabled: Bool) {
        DispatchQueue.main.async {
            self.selectableValueView.set(enabled: enabled)
        }
    }

    func set(duration: TimeInterval?) {
        durationValueLabel.text = duration.map { "send.duration.within".localized($0.approximateHoursOrMinutes) } ?? "send.duration.instant".localized
    }

}

extension SendFeePriorityView: ISelectableValueViewDelegate {

    func onSelectorTap() {
        self.delegate.onFeePrioritySelectorTap()
    }

}
