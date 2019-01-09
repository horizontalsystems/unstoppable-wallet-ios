import Foundation

class FullTransactionInfoProviderFactory {

    private let apiManager: IJSONApiManager
    private let appConfigProvider: IAppConfigProvider
    private let localStorage: ILocalStorage

    init(apiManager: IJSONApiManager, appConfigProvider: IAppConfigProvider, localStorage: ILocalStorage) {
        self.apiManager = apiManager
        self.localStorage = localStorage
        self.appConfigProvider = appConfigProvider
    }

}

extension FullTransactionInfoProviderFactory: IFullTransactionInfoProviderFactory {

    func provider(forCoin coin: String) -> IFullTransactionInfoProvider {
        let explorerId = "Btc.com"

        var adapter: IFullTransactionInfoAdapter
        if coin.range(of: "BTC") != nil {
            let provider: IBitcoinJSONConverter
            if explorerId == "BlockChair.com" {
                let url = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz" : "https://api.blockchair.com/bitcoin/dashboards/transaction/"
                provider = BlockChairBitcoinJSONConverter(url: url)
            } else if explorerId == "BlockExplorer.com" {
                let url = appConfigProvider.testMode ? "https://testnet.blockexplorer.com/api/tx/" : "https://blockexplorer.com/api/tx/"
                provider = BlockExplorerBitcoinJSONConverter(url: url)
            } else if explorerId == "Btc.com" {
                let url = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz" : "https://chain.api.btc.com/v3/tx/"
                provider = BtcComBitcoinJSONConverter(url: url)
            } else {
            // Fallback to our server
                let url = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz" : "https://btc.horizontalsystems.xyz/tx/"
                provider = HorSysBitcoinJSONConverter(url: url)
            }
            adapter = BitcoinTransactionInfoAdapter(jsonConverter: provider, coinCode: coin)
        } else if coin.range(of: "BCH") != nil {
            let provider: IBitcoinJSONConverter
            if explorerId == "BlockChair.com" {
                let url = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://api.blockchair.com/bitcoin-cash/dashboards/transaction/"
                provider = BlockChairBitcoinJSONConverter(url: url)
            } else if explorerId == "BlockExplorer.com" {
                let url = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bitcoincash.blockexplorer.com/api/tx/"
                provider = BlockExplorerBitcoinJSONConverter(url: url)
            } else if explorerId == "Btc.com" {
                let url = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bch-chain.api.btc.com/v3/tx/"
                provider = BtcComBitcoinJSONConverter(url: url)
            } else {
                // Fallback to our server
                let url = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bch.horizontalsystems.xyz/tx/"
                provider = HorSysBitcoinJSONConverter(url: url)
            }
            adapter = BitcoinTransactionInfoAdapter(jsonConverter: provider, coinCode: coin)
        } else {
            let provider: IEthereumJSONConverter
            if explorerId == "Etherscan.io" {
                let url = appConfigProvider.testMode ? "http://eth-testnet.horizontalsystems.xyz" : "https://api.etherscan.io/api?module=proxy&action=eth_getTransactionByHash&txhash="
                provider = HorSysEthereumJSONConverter(url: url)
            } else if explorerId == "BlockChair.com" {
                let url = appConfigProvider.testMode ? "http://eth-testnet.horizontalsystems.xyz" : "https://api.blockchair.com"
                provider = HorSysEthereumJSONConverter(url: url)
            } else {
                provider = HorSysEthereumJSONConverter(url: "https://eth.horizontalsystems.xyz/tx/")
            }
            adapter = EthereumTransactionInfoAdapter(jsonConverter: provider, coinCode: coin)
        }
        return FullTransactionProvider(apiManager: apiManager, adapter: adapter)
    }

}

//        let explorer: IExplorerType
//                let explorerType = BitcoinExplorerType.horSys
//        var explorerHelper: IFullTransactionHelper
//        let host: String
//
//        if coin.range(of: "BTC") != nil {
//            // BTC
//
//            switch explorerType {
//            case .horSys: explorer = BitcoinExplorerType.horSys
//            case .blockExplorer: explorer = BitcoinExplorerType.blockExplorer
//            case .btcCom: explorer = BitcoinExplorerType.btcCom
//            case .blockChair: explorer = BitcoinExplorerType.blockChair
//            }
//        } else if coin.range(of: "BCH") != nil {
//            // BCH
//            switch explorerType {
//            case .horSys: explorer = BitcoinCashExplorerType.horSys
//            case .blockExplorer: explorer = BitcoinCashExplorerType.blockExplorer
//            case .btcCom: explorer = BitcoinCashExplorerType.btcCom
//            case .blockChair: explorer = BitcoinCashExplorerType.blockChair
//            }
//        } else {
//            // ETH and ERC20
//            explorer = EthereumExplorerType.etherScan
//        }
//        if explorer is EthereumExplorerType {
//            return EthereumFullTransactionProvider(apiManager: apiManager, explorerType: explorer, testMode: appConfigProvider.testMode)
//        }
//        return BitcoinFullTransactionProvider(apiManager: apiManager, explorerType: explorer, coinCode: coin, testMode: appConfigProvider.testMode)
//                FullTransactionProvider(apiManager: apiManager, url: host, transactionHelper: explorerHelper, async: true)