import UIKit
//todo extract to GrouviExtensions
extension UITableView {

    public func deselectCell(withCoordinator coordinator: UIViewControllerTransitionCoordinator?, animated: Bool) {
        if let indexPath = indexPathForSelectedRow {
            if let coordinator = coordinator {
                coordinator.animate(alongsideTransition: { [weak self] context in
                    //                    self?.layer.speed = context.isInteractive ? 0.5 : 1
                    self?.deselectRow(at: indexPath, animated: animated)
                }, completion: { [weak self] context in
                    if context.isCancelled {
                        self?.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    }
                    //                    self?.layer.speed = 1
                })
            } else {
                deselectRow(at: indexPath, animated: animated)
            }
        }
    }

}
