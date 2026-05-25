import Combine
import Foundation

public protocol IDepositAdapter: IBaseAdapter {
    var receiveAddress: DepositAddress { get }
    var receiveAddressStatus: DataStatus<DepositAddress> { get }
    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> { get }
}

public extension IDepositAdapter {
    var receiveAddressStatus: DataStatus<DepositAddress> {
        .completed(receiveAddress)
    }

    var receiveAddressPublisher: AnyPublisher<DataStatus<DepositAddress>, Never> {
        Just(receiveAddressStatus).eraseToAnyPublisher()
    }
}
