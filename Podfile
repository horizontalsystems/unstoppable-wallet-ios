platform :ios, '10.0'
use_frameworks!

inhibit_all_warnings!

workspace 'Wallet'

project 'Wallet/Wallet'

target :Wallet do
  project 'Wallet/Wallet'

  pod 'BitcoinKit', git: "https://github.com/ealymbaev/BitcoinKit"
  pod 'Alamofire'
  pod 'ObjectMapper'
  pod 'RxSwift'
  pod 'RxCocoa'
  # pod 'CoreBitcoin', :podspec => 'https://raw.github.com/oleganza/CoreBitcoin/master/CoreBitcoin.podspec'
  # pod 'CoreBitcoin', :git => "https://github.com/andrewtoth/CoreBitcoin.git"
  pod "SnapKit"
end

target :WalletTests do
  project 'Wallet/Wallet'

  pod "Cuckoo"
end
