import UIKit
import ThemeKit
import SnapKit

class IndexedTextFieldCell: TextFieldCell {
    private let indexLabel = UILabel()

    override init() {
        super.init()

        indexLabel.snp.makeConstraints { maker in
            maker.width.equalTo(25)
        }

        indexLabel.textColor = .themeGray
        indexLabel.font = .body

        prependSubview(indexLabel, customSpacing: .margin4)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension IndexedTextFieldCell {

    func set(index: Int) {
        indexLabel.text = "\(index)."
    }

}
