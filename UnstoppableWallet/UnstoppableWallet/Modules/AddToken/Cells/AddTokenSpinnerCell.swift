import UIKit
import ThemeKit
import HUD

class AddTokenSpinnerCell: UITableViewCell {
    private let spinner = HUDActivityView.create(with: .small20)

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        spinner.startAnimating()
    }

}
