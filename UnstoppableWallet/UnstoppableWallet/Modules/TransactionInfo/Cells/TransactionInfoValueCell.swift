//import UIKit
//import ThemeKit
//
//class TransactionInfoValueCell: ThemeCell {
//    private let titleView = TransactionInfoTitleView()
//
//    private let valueLabel = UILabel()
//
//    override init(style: CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        contentView.addSubview(titleView)
//        titleView.snp.makeConstraints { maker in
//            maker.leading.top.bottom.equalToSuperview()
//        }
//
//        contentView.addSubview(valueLabel)
//        valueLabel.snp.makeConstraints { maker in
//            maker.leading.equalTo(titleView.snp.trailing)
//            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
//            maker.centerY.equalToSuperview()
//        }
//
//        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
//        valueLabel.textAlignment = .right
//        valueLabel.font = .subhead1
//        valueLabel.textColor = .themeLeah
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func bind(title: String, value: String?) {
//        super.bind(bottomSeparatorVisible: true)
//
//        titleView.bind(text: title)
//        valueLabel.text = value
//    }
//
//}
