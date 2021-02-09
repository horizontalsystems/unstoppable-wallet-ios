import UIKit
import ThemeKit
import SnapKit

class FormCautionCell: UITableViewCell {
    private let cautionView = FormCautionView()

    init() {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        contentView.addSubview(cautionView)
        cautionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension FormCautionCell {

    func set(caution: Caution?) {
        cautionView.set(caution: caution)
    }

    var onChangeHeight: (() -> ())? {
        get { cautionView.onChangeHeight }
        set { cautionView.onChangeHeight = newValue }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        cautionView.height(containerWidth: containerWidth)
    }

}
