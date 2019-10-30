import UIKit
import UIExtensions
import ActionSheet
import SnapKit

class ChartRateTypeItemView: BaseActionItemView {
    private let buttonHeight: CGFloat = 24
    private let buttonDefaultWidth: CGFloat = 60
    private let buttonTopMargin: CGFloat = 10

    private var buttons = [RespondButton]()

    private let dateLabel = UILabel()
    private let valueLabel = UILabel()

    override var item: ChartRateTypeItem? {
        _item as? ChartRateTypeItem
    }

    override func initView() {
        super.initView()

        valueLabel.font = .appSubhead1
        valueLabel.textColor = .appOz

        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(6)
            maker.centerX.equalToSuperview()
        }

        dateLabel.font = .appCaption
        dateLabel.textColor = .cryptoGray

        addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.top.equalTo(valueLabel.snp.bottom).offset(1)
            maker.centerX.equalToSuperview()
        }

        item?.bindButton = { [weak self] (title, tag, action) in
            self?.addButton(title: title, tag: tag, action: action)
        }
        item?.setSelected = { [weak self] tag in
            self?.setSelected(tag: tag)
        }
        item?.setEnabled = { [weak self] tag in
            self?.setEnabled(tag: tag)
        }
        item?.showPoint = { [weak self] date, value in
            self?.showPoint(date: date, value: value)
        }
    }

    private func showPoint(date: String?, value: String?) {
        dateLabel.text = date
        valueLabel.text = value
        showButtons(date == nil || value == nil)
    }

    private func showButtons(_ show: Bool) {
        dateLabel.isHidden = show
        valueLabel.isHidden = show
        buttons.forEach { $0.isHidden = !show }
    }

    private func setSelected(tag: Int) {
        buttons.forEach { button in
            let nonSelectedState: RespondButton.State = button.state == .disabled ? .disabled : .active
            button.state = button.tag == tag ? .selected : nonSelectedState
        }
    }

    public func setEnabled(tag: Int) {
        buttons.forEach { button in
            if button.tag == tag {
                button.state = button.state == .selected ? .selected : .active
            }
        }
    }

    private func addButton(title: String, tag: Int, action: (() -> ())?) {
        let toggleAction = { [weak self] in
            self?.setSelected(tag: tag)
            action?()
        }

        let button = RespondButton(onTap: toggleAction)
        button.cornerRadius = .cornerRadius12
        button.changeBackground = false
        button.tag = tag
        button.state = .active
        button.textColors = [.active: .appLeah, .selected: .appJacob, .disabled: .appGray50]
        button.backgrounds = [.selected: .appJeremy]
        button.titleLabel.text = title.localized
        button.titleLabel.font = .appSubhead1
        button.titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        button.wrapperView.snp.remakeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin2x)
            maker.top.bottom.equalToSuperview()
        }

        addSubview(button)
        buttons.append(button)

        updateButtonConstraints()
    }

    private func updateButtonConstraints() {
        guard buttons.count != 0 else {
            return
        }

        var lastButton: UIView = buttons[0]
        lastButton.snp.remakeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(buttonTopMargin)
            maker.height.equalTo(buttonHeight)
            if buttons.count == 1 { // just one button
                maker.width.equalTo(buttonDefaultWidth)
            }
        }

        for i in 1..<buttons.count {
            buttons[i].snp.remakeConstraints { maker in
                maker.leading.equalTo(lastButton.snp.trailing).offset(CGFloat.margin2x)
                maker.top.equalToSuperview().offset(buttonTopMargin)
                maker.height.equalTo(buttonHeight)
                maker.width.equalTo(lastButton.snp.width)
                if buttons.count == i + 1 { // last button right constraint
                    maker.right.equalToSuperview().inset(CGFloat.margin4x)
                }
            }
            lastButton = buttons[i]
        }
    }

}
