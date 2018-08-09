import Foundation
@testable import WalletKit

class TestHelper {

    static var checkpointBlock: Block {
        return BlockFactory.shared.block(
                withHeader: BlockHeader(
                        version: 1,
                        previousBlockHeaderReversedHex: "00000000864b744c5025331036aa4a16e9ed1cbb362908c625272150fa059b29",
                        merkleRootReversedHex: "70d6379650ac87eaa4ac1de27c21217b81a034a53abf156c422a538150bd80f4",
                        timestamp: 1337966314,
                        bits: 486604799,
                        nonce: 2391008772
                ),
                height: 2016)
    }

    static var firstBlock: Block {
        return BlockFactory.shared.block(
                withHeader: BlockHeader(
                        version: 1,
                        previousBlockHeaderReversedHex: "0000000089d757fd95d79f7fcc2bc25ca7fc16492dca9aa610730ea05d9d3de9",
                        merkleRootReversedHex: "55de0864e0b96f0dff597b1c138de187dd8c40e859b01b4671f7a92ca1b7a9b9",
                        timestamp: 1337966314,
                        bits: 486604799,
                        nonce: 1716024842
                ),
                previousBlock: checkpointBlock)
    }

    static var secondBlock: Block {
        return BlockFactory.shared.block(
                withHeader: BlockHeader(
                        version: 1,
                        previousBlockHeaderReversedHex: "00000000d4f0ed4d9c3428dd98dabb3ed345c461cf68e8ab61cb048d294a4e4e",
                        merkleRootReversedHex: "9a342c0615d0e5a3256f5b9a7818abecc1c8722ab3a8db8df5595c8635cc11e1",
                        timestamp: 1337966314,
                        bits: 486604799,
                        nonce: 627458064
                ),
                previousBlock: firstBlock)
    }

    static var thirdBlock: Block {
        return BlockFactory.shared.block(
                withHeader: BlockHeader(
                        version: 1,
                        previousBlockHeaderReversedHex: "0000000045fd19b3c01cf7abeb88a1c5b4fea1ba2c26bdbc26a2038106e5d835",
                        merkleRootReversedHex: "4848ea1ec4f1838bc0a6a243b9350d76bfeda63532b6a1cc6bae0df27aba11b3",
                        timestamp: 1337966314,
                        bits: 486604799,
                        nonce: 3977416709
                ),
                previousBlock: secondBlock)
    }

    static var forthBlock: Block {
        return BlockFactory.shared.block(
                withHeader: BlockHeader(
                        version: 1,
                        previousBlockHeaderReversedHex: "00000000215fbd455a4905e35fab995456c8d6442bee8aa9b29b7c353f9a8d80",
                        merkleRootReversedHex: "d45043107540b486cf2079a1d510bfe18053aac2446c5043a2b8eff01668426d",
                        timestamp: 1337966314,
                        bits: 486604799,
                        nonce: 1930065423
                ),
                previousBlock: thirdBlock)
    }

    static var oldBlock: Block {
        return BlockFactory.shared.block(
                withHeader: BlockHeader(
                        version: 1,
                        previousBlockHeaderReversedHex: "0000000036f7b90238ac6b6026be5e121ac3055f19fffd69f28310a76aa4a5bc",
                        merkleRootReversedHex: "3bf8c518a7a1187287516da67cb96733697b1d83eb937e68ae39bd4c08e563b7",
                        timestamp: 1337966144,
                        bits: 486604799,
                        nonce: 1029134858
                ),
                height: 1000)
    }

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
