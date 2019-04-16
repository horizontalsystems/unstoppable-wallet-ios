platform :ios, '11'
use_frameworks!

inhibit_all_warnings!

project 'BankWallet/BankWallet'

def appPods
  pod 'HSBitcoinKit', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/', branch: 'production'
  pod 'HSEthereumKit', git: 'https://github.com/horizontalsystems/ethereum-kit-ios/', branch: 'production'
  pod 'HSFeeRateKit', git: 'https://github.com/horizontalsystems/blockchain-fee-rate-kit-ios'

  pod 'Alamofire'
  pod 'AlamofireImage'
  pod 'ObjectMapper'

  pod 'RxSwift'

  pod 'BigInt'

  pod 'UIExtensions.swift', git: 'https://github.com/horizontalsystems/gui-kit'
  pod 'ActionSheet.swift', git: 'https://github.com/horizontalsystems/gui-kit'
  pod 'HUD.swift', git: 'https://github.com/horizontalsystems/gui-kit'
  pod 'SectionsTableView.swift', git: 'https://github.com/horizontalsystems/gui-kit'

  pod 'KeychainAccess'

  pod 'RxCocoa'
  pod 'SnapKit'

  pod 'GRDB.swift'
  pod 'RxGRDB'
end

target 'Bank Dev T' do
  appPods
end

target 'Bank Dev' do
  appPods
end

target 'Bank' do
  appPods
end

target 'Bank Tests' do
  pod 'RxSwift'
  pod 'Cuckoo'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
    end
  end
end
