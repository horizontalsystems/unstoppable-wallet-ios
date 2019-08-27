import UIKit
import SnapKit

class SendConfirmationRouter {

    static func module(viewItems: [ISendConfirmationViewItemNew], delegate: ISendConfirmationDelegate) -> UIViewController {
//        var views = [UIView]()
//
//        let primaryView = SendConfirmationPrimaryRouter.module(primaryAmount: item.primaryAmount, secondaryAmount: item.secondaryAmount, receiver: item.receiver)
//        views.append(primaryView)
//
//        var memoModule: ISendConfirmationMemoModule?
//
//        if item.showMemo {
//            let (memoView, memo) = SendConfirmationMemoRouter.module()
//            memoModule = memo
//            views.append(memoView)
//        }
//
//        var textFields = [UIView]()
//        if let feeInfo = item.feeInfo {
//            textFields.append(SendConfirmationFieldView(title: "send.fee".localized, text: feeInfo))
//        }
//        if let totalInfo = item.totalInfo {
//            textFields.append(SendConfirmationFieldView(title: "send.confirmation.total".localized, text: totalInfo))
//        }
//        if let estimateTime = item.estimateTime {
//            textFields.append(SendConfirmationFieldView(title: "send.confirmation.estimate_time".localized, text: estimateTime))
//        }
//        if !textFields.isEmpty {
//            let fieldSectionSeparatorView = SendConfirmationSeparatorView(height: SendTheme.confirmationFieldSectionTopMargin)
//            views.append(fieldSectionSeparatorView)
//
//            views.append(contentsOf: textFields)
//        }

        let presenter = SendConfirmationPresenter()
        let viewController = SendConfirmationViewController(delegate: presenter)

        presenter.view = viewController
        presenter.delegate = delegate

        return viewController
    }

}
