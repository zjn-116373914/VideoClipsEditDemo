# Uncomment the next line to define a global platform for your project
# platform :ios, '15.0'

target 'VideoProgressEditDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
end


post_install do |installer|
  #解决第三方框架deployment target版本过低的问题
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end