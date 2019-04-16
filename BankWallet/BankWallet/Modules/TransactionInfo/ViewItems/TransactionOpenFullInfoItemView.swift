import ActionSheet

class TransactionOpenFullInfoItemView: BaseButtonItemView {

    override var item: TransactionOpenFullInfoItem? { return _item as? TransactionOpenFullInfoItem }

    override func initView() {
        super.initView()

        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

}
