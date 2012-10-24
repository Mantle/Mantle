Pod::Spec.new do |s|
  s.name         = "Mantle"
  s.version      = "0.2"
  s.summary      = "Model framework for Cocoa and Cocoa Touch."

  s.homepage     = "https://github.com/github/Mantle"
  s.license      = 'MIT'
  s.author       = { "GitHub" => "support@github.com" }

  s.source       = { :git => "https://github.com/github/Mantle.git", :tag => "0.2" }
  s.source_files = 'Mantle'
  s.framework    = 'Foundation'

  s.ios.deployment_target = '5.0' # there are usages of __weak
  s.osx.deployment_target = '10.7'
  s.requires_arc = true

  s.dependency 'libextobjc/EXTScope'
  s.dependency 'libextobjc/EXTKeyPathCoding'

end


