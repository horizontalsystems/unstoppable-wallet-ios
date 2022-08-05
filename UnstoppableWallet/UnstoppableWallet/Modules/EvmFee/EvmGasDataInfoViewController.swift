import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class EvmGasDataInfoViewController: ThemeActionSheetController {

    init(title: String, description: String) {
        super.init()

        let titleView = BottomSheetTitleView()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.title = title
        titleView.image = UIImage(named: "circle_information_24")?.withTintColor(.themeGray)
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        let label = UILabel()

        view.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin32)
            maker.top.equalTo(titleView.snp.bottom)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin32)
        }

        label.text = description
        label.numberOfLines = 0
        label.font = .body
        label.textColor = .themeBran
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
