import UIKit
import BitcoinKit
import RxSwift

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let disposeBag = DisposeBag()

    var transactions = [TransactionData]()

    @IBOutlet weak var currentBalanceLabel: UILabel?
    @IBOutlet weak var tableView: UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let words = try? Mnemonic.generate(strength: .default, language: .english) else {
            return
        }

        print("\nWords: \(words.joined(separator: " "))")

        let seed = Mnemonic.seed(mnemonic: words)

        print("\nSeed (\(seed.count)): \(seed.map { String($0) }.joined(separator: " "))")

//        perform()
    }

    private func perform() {
        let mnemonic = ["used", "ugly", "meat", "glad", "balance", "divorce", "inner", "artwork", "hire", "invest", "already", "piano"]

        //        print("Mnemonic: \(mnemonic.joined(separator: ", "))")

        let seed = Mnemonic.seed(mnemonic: mnemonic, passphrase: "")

        //        print("Seed: \(seed)")

        let hdWallet = HDWallet(seed: seed, network: Network.testnet)
        //        let hdWallet = HDWallet(seed: seed, network: Network.mainnet)

        var addresses = [String]()

        let fromAddress = String(describing: try! hdWallet.receiveAddress(index: 1))
        let fromPrivateKey = try! hdWallet.privateKey(index: 1)
        let changeAddress = String(describing: try! hdWallet.changeAddress(index: 0))

//        let destAddress = String(describing: try! hdWallet.receiveAddress(index: 4))
        let destAddress = "2NG3Z8ov5MeLZpZtaiQHErQM5NTvyNDB2xq"
//        let destAddress = "mnopQ2S29rhuKLikR2NfNBztchxkm2CJfZ"

//        print("PRIVATE KEY: \(fromPrivateKey.raw.hex)")

        for i in 0...20 {
            if let address = try? hdWallet.receiveAddress(index: UInt32(i)) {
                //                print("Receive Address \(i): \(address)")
                addresses.append(String(describing: address))
            }
        }

        for i in 0...20 {
            if let address = try? hdWallet.changeAddress(index: UInt32(i)) {
                //                print("Change Address \(i): \(address)")
                addresses.append(String(describing: address))
            }
        }

//        NetworkManager.instance.unspentOutputData(forAddresses: [fromAddress])
//                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { [weak self] data in
//                    var totalValue: Int64 = 0
//
//                    for unspentOutput in data.unspentOutputs {
//                        //                        print("Value: \(unspentOutput.value), TX Output: \(unspentOutput.outputIndex), Confirmations: \(unspentOutput.confirmations)")
//                        totalValue += unspentOutput.value
//                    }
//
//                    //                    print(String(format: "Total Value: %.08f BTC", Double(totalValue) / 100000000))
//
//                    self?.currentBalanceLabel?.text = String(format: "%.08f BTC", Double(totalValue) / 100000000)
//
//                    if let unspentOutput = data.unspentOutputs.first {
////                        self?.createTransaction(unspentOutput: unspentOutput, privateKey: fromPrivateKey.raw, destinationAddressString: destAddress, changeAddressString: changeAddress)
//                    }
//                })
//                .disposed(by: disposeBag)

//        NetworkManager.instance.addressesData(forAddresses: addresses)
//                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
//                .observeOn(MainScheduler.instance)
//                .subscribe(onNext: { [weak self] data in
//                    self?.transactions = data.transactions
//                    self?.tableView?.reloadData()
//                })
//                .disposed(by: disposeBag)


        //        let transactionHex = "0200000001c534b75b584337e512954735af51892cc9e241a8ec360a86ea834c8ad4ca78b90000000000ffffffff01f00768590000000017a91400a97e390b11bef138ac80b74910373155bdc0308700000000"
        //
        //        if let data = Data(hex: transactionHex) {
        //            print("Got Data")
        //
        //            let transaction = Transaction.deserialize(data)
        //
        //            print(transaction.inputs.count)
        //            print(transaction.outputs.count)
        //            print(transaction.serialized().hex)
        //
        ////            print(Crypto.sha256sha256(transaction.serialized()).hex)
        //        }

        //        BTCTransactionBuilder
        //        BTCTransactionOutput
        //        BTCTransaction
    }

    private func createTransaction(unspentOutput: UnspentOutput, privateKey: Data, destinationAddressString: String, changeAddressString: String) {
        let amount: Int64 = 3000000
        let fee: Int64 = 2500

        let ascii = destinationAddressString.cString(using: .ascii)
        print("ASCII: \(ascii)")

        let composedData = BTCDataFromBase58CheckCString(ascii) as Data
        print("Composed Data: \(composedData.count)")

        print("version: \(composedData.first)")



        let destinationAddress = BTCPublicKeyAddressTestnet(string: destinationAddressString)
        let changeAddress = BTCPublicKeyAddressTestnet(string: changeAddressString)

        guard let key = BTCKey(privateKey: privateKey) else {
            print("NO PRIVATE KEY")
            return
        }

        let utxo = BTCTransactionOutput()
        utxo.value = unspentOutput.value
        utxo.index = UInt32(unspentOutput.index)
        utxo.confirmations = UInt(unspentOutput.confirmations)
        utxo.transactionHash = BTCDataFromHex(unspentOutput.transactionHash)
        utxo.script = BTCScript(data: BTCDataFromHex(unspentOutput.script))

        let spent = Int64(utxo.value)

        print("isPayToPublicKeyHashScript: \(utxo.script.isPayToPublicKeyHashScript)")

        let input = BTCTransactionInput()
        input.previousHash = utxo.transactionHash
        input.previousIndex = utxo.index

        let transaction = BTCTransaction()
        transaction.addInput(input)

        print("Total Spent: \(spent)")
        print("Total to Destination: \(amount)")
        print("Total Fee: \(fee)")
        print("Total Change: \(spent - (amount + fee))")

        let paymentOut = BTCTransactionOutput(value: amount, address: destinationAddress)
        let changeOut = BTCTransactionOutput(value: spent - (amount + fee), address: changeAddress)

        print("OUT ADDRESS: \(destinationAddress)")
        let script = BTCScript(address: destinationAddress)
        print("OUT SCRIPT: \(script)")

        transaction.addOutput(changeOut)
        transaction.addOutput(paymentOut)


        let cpk = key.compressedPublicKey as Data

        guard let hash = try? transaction.signatureHash(for: utxo.script, inputIndex: 0, hashType: .BTCSignatureHashTypeAll) else {
            print("No Hash")
            return
        }

        let testScript = BTCScript(address: BTCPublicKeyAddressTestnet(data: BTCHash160(cpk) as! Data))

        if utxo.script.data == testScript?.data {
            print("YES")
        } else {
            print("NO")
        }

        guard let signatureForScript = key.signature(forHash: hash, hashType: .BTCSignatureHashTypeAll) else {
            print("No Script")
            return
        }

        let sigScript = BTCScript()!
        sigScript.appendData(signatureForScript)
        sigScript.appendData(cpk)

        input.signatureScript = sigScript



//
//        guard let hash = try? transaction.signatureHash(for: utxo.script, inputIndex: 0, hashType: .BTCSignatureHashTypeAll) else {
//            print("No Hash")
//            return
//        }
//
//        guard let signatureForScript = key.signature(forHash: hash, hashType: .BTCSignatureHashTypeAll) else {
//            print("No Script")
//            return
//        }
//
//        sigScript.appendData(signatureForScript)
//        sigScript.appendData(key.publicKey as Data)
//
//        input.signatureScript = sigScript



        do {
            if let sm = BTCScriptMachine(transaction: transaction, inputIndex: 0) {
                let result = try sm.verify(withOutputScript: utxo.script)
                print(result)
            }
        } catch {
            print("Error: \(error)")
        }

        print(transaction.hex)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TransactionCell {
            cell.bind(transaction: transactions[indexPath.row])
        }
    }

}
