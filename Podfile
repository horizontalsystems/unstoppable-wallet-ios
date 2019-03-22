platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

project 'BankWallet/BankWallet'

def appPods
  pod 'HSBitcoinKit', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/', branch: 'production'
  pod 'HSEthereumKit', git: 'https://github.com/horizontalsystems/ethereum-kit-ios/'

  pod 'Alamofire'
  pod 'AlamofireImage'
  pod 'ObjectMapper'

  pod 'RxSwift'

  pod 'BigInt'

  pod 'GrouviExtensions'
  pod 'GrouviActionSheet', git: 'https://github.com/horizontalsystems/GrouviActoinSheet'
  pod 'GrouviHUD', git: 'https://github.com/horizontalsystems/GrouviHUD'
  pod 'SectionsTableViewKit'

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
