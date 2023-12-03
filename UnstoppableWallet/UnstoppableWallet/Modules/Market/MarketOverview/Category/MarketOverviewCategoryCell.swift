import MarketKit
import SnapKit
import UIKit

class MarketOverviewCategoryCell: UITableViewCell {
    static let cellHeight: CGFloat = MarketCategoryView.height + 2 * .margin16

    var onSelect: ((String) -> Void)?

    var viewItems = [MarketOverviewCategoryViewModel.ViewItem]() {
        didSet {
            build()
        }
    }

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let leadingView = UIView()
    private let trailingView = UIView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
            make.top.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

        scrollView.isPagingEnabled = true
        scrollView.clipsToBounds = false
        scrollView.showsHorizontalScrollIndicator = false

        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView).inset(-CGFloat.margin4)
            make.top.bottom.equalTo(scrollView)
            make.height.equalTo(scrollView)
        }

        stackView.spacing = .margin8

        leadingView.snp.makeConstraints { make in
            make.width.equalTo(0)
        }
        trailingView.snp.makeConstraints { make in
            make.width.equalTo(0)
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func build() {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
        }

        stackView.addArrangedSubview(leadingView)

        var bufferView: UIView?

        for (index, viewItem) in viewItems.enumerated() {
            let view = MarketCategoryView()
            view.set(viewItem: viewItem)

            if let _bufferView = bufferView {
                let stackView = UIStackView(arrangedSubviews: [_bufferView, view])
                stackView.spacing = .margin8
                stackView.distribution = .fillEqually

                self.stackView.addArrangedSubview(stackView)

                stackView.snp.makeConstraints { make in
                    make.width.equalTo(scrollView).offset(-CGFloat.margin8)
                }

                bufferView = nil
            } else if index == viewItems.count - 1 {
                let stackView = UIStackView(arrangedSubviews: [view, UIView()])
                stackView.spacing = .margin8
                stackView.distribution = .fillEqually

                self.stackView.addArrangedSubview(stackView)

                stackView.snp.makeConstraints { make in
                    make.width.equalTo(scrollView).offset(-CGFloat.margin8)
                }
            } else {
                bufferView = view
            }
        }

        stackView.addArrangedSubview(trailingView)
    }
}
