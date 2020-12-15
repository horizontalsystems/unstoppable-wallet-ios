import UIKit
import SnapKit
import ThemeKit

class MarketCell: UITableViewCell {
    static let height: CGFloat = 61

    private let gradientView = GradientPercentBar()
    private let button = ThemeButton()
    private let inputField = UITextField()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(gradientView)
        gradientView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(20)
            maker.centerY.equalToSuperview()
        }

        contentView.addSubview(button)
        button.snp.makeConstraints { maker in
            maker.leading.equalTo(gradientView.snp.trailing).offset(50)
            maker.top.equalToSuperview().inset(20)
            maker.width.equalTo(100)
            maker.height.equalTo(40)
        }

        button.apply(style: .primaryGray)
        button.setTitle("change", for: .normal)
        button.addTarget(self, action: #selector(tapB), for: .touchUpInside)

        contentView.addSubview(inputField)
        inputField.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(20)
            maker.top.equalToSuperview().inset(20)
            maker.leading.equalTo(button.snp.trailing).offset(10)
            maker.height.equalTo(40)
        }
        inputField.textColor = .white
    }

    @objc func tapB() {
        if let val = Int(inputField.text ?? "") {
            print("Set \(val.description) to gradient")
            gradientView.set(value: Decimal(val) / 100)
            return
        }

        let i = Int.random(in: -110...110)
        if i < -100 || i > 100 {
            print("Set nil to gradient")
            gradientView.set(value: nil)
            return
        }
        let floatI = CGFloat(i) / 100
        print("Set \(floatI.description) to gradient")
        gradientView.set(value: floatI.decimalValue)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind() {
    }

}
