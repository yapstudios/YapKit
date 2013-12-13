Pod::Spec.new do |s|
  s.name         = "YapKit"
  s.version      = "0.1"
  s.summary      = "Yap Studios Core Component Framework"
  s.homepage     = "http://yapstudios.com/"
  s.license      = 'None'
  s.author       = { "Yap Studios" => "contact@yapstudios.com" }
  s.source       = { :git => "https://github.com/yapstudios/YapKit.git" }
  s.requires_arc = true
  s.xcconfig     = { 'GCC_TREAT_WARNINGS_AS_ERRORS' => 'YES' }
# s.compiler_flags = { 'WARNING_CFLAGS' => '-Wno-error=unused-variable -Werror' }

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'Classes/*.{h,m}'
  s.header_mappings_dir =  'Classes'

end
