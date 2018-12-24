platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

project 'BankWallet/BankWallet'

def appPods
  pod 'HSBitcoinKit'
  pod 'HSEthereumKit'

  pod 'Alamofire'
  pod 'ObjectMapper'

  pod 'RxSwift'

  pod 'BigInt'
  pod 'RealmSwift'
  pod "RxRealm"

  pod 'GrouviExtensions'
  pod 'GrouviActionSheet'
  pod 'GrouviHUD'
  pod 'SectionsTableViewKit'

  pod 'KeychainAccess'

  pod 'RxCocoa'
  pod "SnapKit"
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
  pod 'RealmSwift'
  pod 'RxSwift'
  pod "Cuckoo"
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
    end
  end
end
