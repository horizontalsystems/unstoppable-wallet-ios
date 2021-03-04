//class ItemSelectorViewModel {
//    weak var view: IAlertView?
//
//    private let viewItems: [WrappedViewItem]
//    private let onSelect: (Int) -> ()
//
//    private let router: IAlertRouter
//
//    init(viewItems: [WrappedViewItem], onSelect: @escaping (Int) -> (), router: IAlertRouter) {
//        self.viewItems = viewItems
//        self.onSelect = onSelect
//        self.router = router
//    }
//
//}
//
//extension ItemSelectorViewModel: IAlertViewDelegate {
//
//    func onLoad() {
//        view?.set(viewItems: viewItems)
//    }
//
//    func onTapViewItem(index: Int) {
//        onSelect(index)
//        router.close()
//    }
//
//}
