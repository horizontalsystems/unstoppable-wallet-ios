platform :ios, '13'
use_modular_headers!

inhibit_all_warnings!

project 'UnstoppableWallet/UnstoppableWallet'

def appPods
  pod 'BitcoinKit.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios.git'
  # pod 'BitcoinKit.swift', path: '../bitcoin-kit-ios/'
  pod 'LitecoinKit.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios.git'
  # pod 'LitecoinKit.swift', path: '../bitcoin-kit-ios/'
  pod 'BitcoinCashKit.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios.git'
  # pod 'BitcoinCashKit.swift', path: '../bitcoin-kit-ios/'
  pod 'DashKit.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios.git'
  # pod 'DashKit.swift', path: '../bitcoin-kit-ios/'
  pod 'Hodler.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios.git'

  pod 'BitcoinCore.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios.git'
  # pod 'BitcoinCore.swift', path: '../bitcoin-kit-ios/'

  pod 'ZcashLightClientKit', :git => 'https://github.com/zcash/ZcashLightClientKit', :tag => '0.12.0-beta.6'
#  pod 'ZcashLightClientKit', path: '../ZcashLightClientKit'

  pod 'EthereumKit.swift', git: 'https://github.com/horizontalsystems/ethereum-kit-ios'
  # pod 'EthereumKit.swift', path: '../ethereum-kit-ios/'
  pod 'Erc20Kit.swift', git: 'https://github.com/horizontalsystems/ethereum-kit-ios'
  # pod 'Erc20Kit.swift', path: '../ethereum-kit-ios/'
  pod 'UniswapKit.swift', git: 'https://github.com/horizontalsystems/ethereum-kit-ios'
  # pod 'UniswapKit.swift', :path => '../ethereum-kit-ios'
  pod 'OneInchKit.swift', git: 'https://github.com/horizontalsystems/ethereum-kit-ios'
  # pod 'OneInchKit.swift', :path => '../ethereum-kit-ios'

  pod 'BinanceChainKit.swift', git: 'https://github.com/horizontalsystems/binance-chain-kit-ios'
  # pod 'BinanceChainKit.swift', path: '../binance-chain-kit-ios/'

  pod 'HdWalletKit.swift', git: 'https://github.com/horizontalsystems/hd-wallet-kit-ios'
  # pod 'HdWalletKit.swift', path: '../hd-wallet-kit-ios/'

  pod 'MarketKit.swift', git: 'https://github.com/horizontalsystems/market-kit-ios/'
  # pod 'MarketKit.swift', path: '../market-kit-ios/'
  pod 'FeeRateKit.swift', git: 'https://github.com/horizontalsystems/blockchain-fee-rate-kit-ios'
  # pod 'FeeRateKit.swift', path: '../blockchain-fee-rate-kit-ios/'

  pod 'HsToolKit.swift', git: 'https://github.com/horizontalsystems/hs-tool-kit-ios'
  # pod 'HsToolKit.swift', path: '../hs-tool-kit-ios/'

  pod 'UIExtensions.swift', git: 'https://github.com/horizontalsystems/gui-kit/'
  # pod 'UIExtensions.swift', path: '../gui-kit/'
  pod 'ComponentKit.swift', git: 'https://github.com/horizontalsystems/component-kit-ios/'
  # pod 'ComponentKit.swift', path: '../component-kit-ios/'
  pod 'ThemeKit.swift', git: 'https://github.com/horizontalsystems/component-kit-ios/'
  # pod 'ThemeKit.swift', path: '../component-kit-ios/'
  pod 'LanguageKit.swift', git: 'https://github.com/horizontalsystems/component-kit-ios/'
  # pod 'LanguageKit.swift', path: '../component-kit-ios/'
  pod 'StorageKit.swift', git: 'https://github.com/horizontalsystems/component-kit-ios/'
  # pod 'StorageKit.swift', path: '../component-kit-ios/'
  pod 'PinKit.swift', git: 'https://github.com/horizontalsystems/component-kit-ios/'
  # pod 'PinKit.swift', path: '../component-kit-ios/'
  pod 'ScanQrKit.swift', git: 'https://github.com/horizontalsystems/component-kit-ios/'
  # pod 'ScanQrKit.swift', path: '../component-kit-ios/'
  pod 'CurrencyKit.swift', git: 'https://github.com/horizontalsystems/component-kit-ios/'
  # pod 'CurrencyKit.swift', path: '../component-kit-ios/'
  pod 'ModuleKit.swift', git: 'https://github.com/horizontalsystems/component-kit-ios/'
  # pod 'ModuleKit.swift', path: '../component-kit-ios/'

  pod 'ActionSheet.swift', git: 'https://github.com/horizontalsystems/gui-kit/'
  # pod 'ActionSheet.swift', path: '../gui-kit/'
  pod 'HUD.swift', git: 'https://github.com/horizontalsystems/gui-kit/'
  # pod 'HUD.swift', path: '../gui-kit/'
  pod 'Chart.swift', git: 'https://github.com/horizontalsystems/gui-kit/'
  # pod 'Chart.swift', path: '../gui-kit/'
  pod 'SectionsTableView.swift', git: 'https://github.com/horizontalsystems/gui-kit/'
  # pod 'SectionsTableView.swift', path: '../gui-kit/'

  pod 'Alamofire'
  pod 'Kingfisher'
  pod 'ObjectMapper'

  pod 'GRDB.swift'

  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'RxGRDB'

  pod 'BigInt'
  pod 'KeychainAccess'
  pod 'SnapKit'

  pod 'WalletConnect', git: 'https://github.com/horizontalsystems/wallet-connect-swift'

  pod 'EthereumABI', git: 'https://github.com/horizontalsystems/EthereumABI'
  pod 'UnstoppableDomainsResolution', '~> 3.0.0'
end

target 'Unstoppable Dev T' do
  appPods
end

target 'Unstoppable Dev' do
  appPods
end

target 'Unstoppable' do
  appPods
end

target 'Unstoppable Tests' do
  appPods
  pod 'Cuckoo'
  pod 'Quick'
  pod 'Nimble'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
