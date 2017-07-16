Pod::Spec.new do |s|
  s.name             = 'DownloadingProgressButton'
  s.version          = '0.1.0'
  s.summary          = 'Button with progress indicator.'
  s.description      = <<-DESC
Button with progress indicator. Use as downloading indicator or whatever you want. 
                       DESC
  s.homepage         = 'https://github.com/VAndrJ/DownloadingProgressButton'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'VAndrJ' => 'vandrjios@gmail.com' }
  s.source           = { :git => 'https://github.com/VAndrJ/DownloadingProgressButton.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'DownloadingProgressButton/Classes/**/*'
  s.frameworks = 'Foundation'

end
