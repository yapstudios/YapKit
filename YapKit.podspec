Pod::Spec.new do |s|
  s.name         = "YapKit"
  s.version      = "1.0.0"
  s.summary      = "Yap Studios General Purpose Utilities"
  s.homepage     = "http://yapstudios.com/"
  s.license      = 'MIT'

  s.author       = {
    "Yap Studios" => "contact@yapstudios.com"
  }

  s.source       = {
    :git => 'https://github.com/yapstudios/YapKit.git',
    :tag => s.version
  }

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '10.0'

  s.source_files = 'Source/*.{h,m,swift}'

  s.tvos.exclude_files = 'Source/YapIntersection.swift', 'Source/YapNavigationBar.swift', 'Source/YapSoundFX.{h,m}'
end
