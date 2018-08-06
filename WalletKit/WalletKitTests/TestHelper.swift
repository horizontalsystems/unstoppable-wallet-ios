import Foundation
@testable import WalletKit

class TestHelper {

    static var preCheckpointBlockHeader: BlockHeader {
        return BlockHeader(
                version: 536870912,
                previousBlockHeaderReversedHex: "00000000000003b0bfa9f11f946df6502b3fe5863cf4768dcf9e35b5fc94f9b7",
                merkleRootReversedHex: "99344f97da778690e2af9729a7302c6f6bd2197a1b682ebc142f7de8236a85b9",
                timestamp: 1530756271,
                bits: 436469756,
                nonce: 1373357969
        )
    }

    static let preCheckpointBlockHeight: Int = 1350719

    static var checkpointBlockHeader: BlockHeader {
        return BlockHeader(
                version: 536870912,
                previousBlockHeaderReversedHex: "00000000000002ac6d5c058c9932f350aeef84f6e334f4e01b40be4db537f8c2",
                merkleRootReversedHex: "9e172a04fc387db6f273ee96b4ef50732bb4b06e494483d182c5722afd8770b3",
                timestamp: 1530756778,
                bits: 436273151,
                nonce: 4053884125
        )
    }

    static var p2pkhTransaction: Transaction {
        let transaction = TransactionFactory.shared.transaction(version: 1, inputs: [
            TransactionInputFactory.shared.transactionInput(
                    withPreviousOutputTxReversedHex: Data(Data(hex: "a6d1ce683f38a84cfd88a9d48b0ba2d7a8def00f8517e3da02c86fce6c7863d7")!.reversed()), withPreviousOutputIndex: 0,
                    script: Data(hex: "4730440220302e597d74aebcb0bf7f372be156252017af190bd586466104b079fba4b7efa7022037ebbf84e096ef3d966123a93a83586012353c1d2c11c967d21acf1c94c45df001210347235e12207d21b6093d9fd93a0df4d589a0d44252b98b2e934a8da5ab1d1654")!,
                    sequence: 4294967295
            )
        ], outputs: [
            TransactionOutputFactory.shared.transactionOutput(withValue: 10792000, withLockingScript: Data(hex: "76a9141ec865abcb88cec71c484d4dadec3d7dc0271a7b88ac")!, withIndex: 0),
            TransactionOutputFactory.shared.transactionOutput(withValue: 0, withLockingScript: Data(hex: "6a4c500000b919000189658af37cd16dbd16e4186ea13c5d8e1f40c5b5a0958326067dd923b8fc8f0767f62eb9a7fd57df4f3e775a96ca5b5eabf5057dff98997a3bbd011366703f5e45075f397f7f3c8465da")!, withIndex: 1),
        ], lockTime: 0)

        return transaction
    }

    static var p2pkTransaction: Transaction {
        let transaction = TransactionFactory.shared.transaction(version: 1, inputs: [
            TransactionInputFactory.shared.transactionInput(
                    withPreviousOutputTxReversedHex: Data(Data(hex: "a6d1ce683f38a84cfd88a9d48b0ba2d7a8def00f8517e3da02c86fce6c7863d7")!.reversed()), withPreviousOutputIndex: 0,
                    script: Data(hex: "4730440220302e597d74aebcb0bf7f372be156252017af190bd586466104b079fba4b7efa7022037ebbf84e096ef3d966123a93a83586012353c1d2c11c967d21acf1c94c45df001210347235e12207d21b6093d9fd93a0df4d589a0d44252b98b2e934a8da5ab1d1654")!,
                    sequence: 4294967295
            )
        ], outputs: [
            TransactionOutputFactory.shared.transactionOutput(withValue: 10, withLockingScript: Data(hex: "21037d56797fbe9aa506fc263751abf23bb46c9770181a6059096808923f0a64cb15ac")!, withIndex: 1),
        ], lockTime: 0)

        return transaction
    }

    static var p2shTransaction: Transaction {
        let transaction = TransactionFactory.shared.transaction(version: 1, inputs: [
            TransactionInputFactory.shared.transactionInput(
                    withPreviousOutputTxReversedHex: Data(Data(hex: "a6d1ce683f38a84cfd88a9d48b0ba2d7a8def00f8517e3da02c86fce6c7863d7")!.reversed()), withPreviousOutputIndex: 0,
                    script: Data(hex: "4730440220302e597d74aebcb0bf7f372be156252017af190bd586466104b079fba4b7efa7022037ebbf84e096ef3d966123a93a83586012353c1d2c11c967d21acf1c94c45df001210347235e12207d21b6093d9fd93a0df4d589a0d44252b98b2e934a8da5ab1d1654")!,
                    sequence: 4294967295
            )
        ], outputs: [
            TransactionOutputFactory.shared.transactionOutput(withValue: 10, withLockingScript: Data(hex: "a914bd82ef4973ebfcbc8f7cb1d540ef0503a791970b87")!, withIndex: 1),
        ], lockTime: 0)

        return transaction
    }

    static func address(pubKeyHash: Data = Data(hex: "1ec865abcb88cec71c484d4dadec3d7dc0271a7b")!) -> Address {
        let address = Address()
        address.publicKeyHash = pubKeyHash

        return address
    }

}
