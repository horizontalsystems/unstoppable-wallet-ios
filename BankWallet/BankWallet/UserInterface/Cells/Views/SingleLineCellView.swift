import UIKit
import SnapKit

class SingleLineCellView: UIView {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.font = .appBody
        label.textColor = .appOz

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?) {
        label.text = text
    }

}
