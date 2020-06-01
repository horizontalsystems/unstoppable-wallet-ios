import UIKit
import ThemeKit

class AddErc20TokenSpinnerCell: UITableViewCell {
    private let spinner = UIActivityIndicatorView()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.color = .themeOz
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimating() {
        spinner.startAnimating()
    }

}
