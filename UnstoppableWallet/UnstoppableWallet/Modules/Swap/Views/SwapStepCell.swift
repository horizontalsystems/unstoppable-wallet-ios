import UIKit
import SnapKit

class SwapStepCell: UITableViewCell {
    private let firstStepView = StepBadgeView()
    private let separatorView = UIView()
    private let lastStepView = StepBadgeView()
    var isVisible = true

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        addSubview(firstStepView)
        firstStepView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.width.height.equalTo(CGFloat.margin24)
        }

        firstStepView.text = "1"
        firstStepView.set(active: true)

        addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.equalTo(firstStepView.snp.trailing).offset(CGFloat.margin8)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(CGFloat.margin2)
        }

        separatorView.backgroundColor = .themeSteel20
        separatorView.clipsToBounds = true
        separatorView.layer.cornerRadius = 1

        addSubview(lastStepView)
        lastStepView.snp.makeConstraints { maker in
            maker.leading.equalTo(separatorView.snp.trailing).offset(CGFloat.margin8)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.width.height.equalTo(CGFloat.margin24)
        }

        lastStepView.text = "2"
        lastStepView.set(active: false)

    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func set(first: Bool) {
        firstStepView.set(active: first)
        lastStepView.set(active: !first)
    }

    var cellHeight: CGFloat {
        isVisible ? 24 : 0
    }

}
