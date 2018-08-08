platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'Wallet'

project 'Wallet/Wallet'
project 'WalletKit/WalletKit'

def kit_pods
  pod 'Alamofire'
  pod 'ObjectMapper'

  pod 'RxSwift'

  pod 'BigInt'
  pod 'RealmSwift'
  pod "RxRealm"
end

target :Bank do
  project 'Wallet/Wallet'

  kit_pods

  pod 'GrouviExtensions'
  pod 'GrouviActionSheet'

  pod 'RxCocoa'
  pod "SnapKit"
end

target :WalletKit do
  project 'WalletKit/WalletKit'
  kit_pods
end

target :WalletKitTests do
  project 'WalletKit/WalletKit'

  pod "Cuckoo"
end

target :WalletTests do
  project 'Wallet/Wallet'

  pod "Cuckoo"
end
