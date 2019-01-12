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
        let explorerId = "HorizontalSystems.xyz"

        var adapter: IFullTransactionInfoAdapter
        var apiUrl: String
        var url: String
        if coin.range(of: "BTC") != nil {
            let converter: IBitcoinJSONConverter
            if explorerId == "BlockChair.com" {
                apiUrl = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz/tx/" : "https://api.blockchair.com/bitcoin/dashboards/transaction/"
                url = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz" : "https://blockchair.com/bitcoin/transaction/"
                converter = BlockChairBitcoinJSONConverter()
            } else if explorerId == "BlockExplorer.com" {
                apiUrl = appConfigProvider.testMode ? "https://testnet.blockexplorer.com/api/tx/" : "https://blockexplorer.com/api/tx/"
                url = appConfigProvider.testMode ? "https://testnet.blockexplorer.com/tx/" : "https://blockexplorer.com/tx/"
                converter = BlockExplorerBitcoinJSONConverter()
            } else if explorerId == "Btc.com" {
                apiUrl = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz" : "https://chain.api.btc.com/v3/tx/"
                url = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz" : "https://btc.com/"
                converter = BtcComBitcoinJSONConverter()
            } else {
            // Fallback to our server
                apiUrl = appConfigProvider.testMode ? "http://btc-testnet.horizontalsystems.xyz/tx/" : "https://btc.horizontalsystems.xyz/tx/"
                url = apiUrl
                converter = HorSysBitcoinJSONConverter()
            }
            adapter = BitcoinTransactionInfoAdapter(jsonConverter: converter, coinCode: coin)
        } else if coin.range(of: "BCH") != nil {
            let converter: IBitcoinJSONConverter
            if explorerId == "BlockChair.com" {
                apiUrl = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz/tx/" : "https://api.blockchair.com/bitcoin-cash/dashboards/transaction/"
                url = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz/tx/" : "https://blockchair.com/bitcoin-cash/transaction/"
                converter = BlockChairBitcoinJSONConverter()
            } else if explorerId == "BlockExplorer.com" {
                apiUrl = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bitcoincash.blockexplorer.com/api/tx/"
                url = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bitcoincash.blockexplorer.com/tx/"
                converter = BlockExplorerBitcoinJSONConverter()
            } else if explorerId == "Btc.com" {
                apiUrl = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bch-chain.api.btc.com/v3/tx/"
                url = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bch.btc.com/"
                converter = BtcComBitcoinJSONConverter()
            } else {
                // Fallback to our server
                apiUrl = appConfigProvider.testMode ? "http://bch-testnet.horizontalsystems.xyz" : "https://bch.horizontalsystems.xyz/tx/"
                url = apiUrl
                converter = HorSysBitcoinJSONConverter()
            }
            adapter = BitcoinTransactionInfoAdapter(jsonConverter: converter, coinCode: coin)
        } else {
            let converter: IEthereumJSONConverter
            if explorerId == "Etherscan.io" {
                apiUrl = appConfigProvider.testMode ? "http://eth-testnet.horizontalsystems.xyz" : "https://api.etherscan.io/api?module=proxy&action=eth_getTransactionByHash&txhash="
                url = appConfigProvider.testMode ? "https://ropsten.etherscan.io/tx/" : "https://etherscan.io/tx/"
                converter = EtherscanEthereumJSONConverter()
            } else if explorerId == "BlockChair.com" {
                apiUrl = appConfigProvider.testMode ? "http://eth-testnet.horizontalsystems.xyz" : "https://api.blockchair.com/ethereum/dashboards/transaction/"
                url = appConfigProvider.testMode ? "http://eth-testnet.horizontalsystems.xyz" : "https://blockchair.com/ethereum/transaction/"
                converter = BlockChairEthereumJSONConverter()
            } else {
                apiUrl = appConfigProvider.testMode ? "http://eth-testnet.horizontalsystems.xyz" : "http://eth.horizontalsystems.xyz"
                url = apiUrl
                converter = HorSysEthereumJSONConverter()
            }
            adapter = EthereumTransactionInfoAdapter(jsonConverter: converter, coinCode: coin)
        }
        return FullTransactionProvider(apiManager: apiManager, adapter: adapter, providerName: explorerId, apiUrl: apiUrl, url: url)
    }

}
