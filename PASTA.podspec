#
# Be sure to run `pod lib lint PASTA.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PASTA'
  s.version          = '0.1.0'
  s.summary          = 'Swift SDK to detect passive Tangibles using iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
PASTA is a SDK developed to detect passive Tangibles on iOS.
It features detection, error handling on marker loss, and distinction of Tangibles.
                       DESC

  s.homepage         = 'https://github.com/aroyarexs/PASTA'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Aaron Krämer' => 'aaron@cs.rwth-aachen.de' }
  s.source           = { :git => 'https://github.com/aroyarexs/PASTA.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.1'

  s.source_files = 'PASTA/Classes/**/*'
  
  # s.resource_bundles = {
  #   'PASTA' => ['PASTA/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit'
  s.dependency 'Metron', '~> 1.0'

  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/*'
    test_spec.dependency 'Quick', '~> 1.1.0' # This dependency will only be linked with your tests.
    test_spec.dependency 'Nimble', '~> 6.1'
  end 
end
