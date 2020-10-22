#!/usr/bin/ruby

require 'optparse'

$podspec_version_regex = /\.version\s*=\s*(["'])(.+)(?=\1)/
$podspec_name = 'SwiftyPlayer.podspec'

def run_cmd(cmd)
  puts cmd
  system cmd
  raise "cmd failed, #{cmd}" unless $?.exitstatus == 0
end

def options_setting
  options = {all: false}

  OptionParser.new do |opts|
    opts.banner = "Usage: release.rb [version]"
    opts.separator "发布新版 SwiftyPlayer"
    # opts.separator "Options:"
    # options (switch - true/false)
    # opts.on("-a", "--all", "是否发布通知所有业务") do |a|
    #   options[:all] = a
    # end
  end.parse!

  return options[:all]
end

def get_version
  version = ARGV[0]
  throw '版本号没传' if version.nil?
  pattern = /(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?/
  throw '版本号不符合语义化' unless pattern.match?(version)
  podspec_content = File.read(File.join($podspec_name))
  local_version = $podspec_version_regex.match(podspec_content).captures[1]
  throw "传入的版本号比本地的小，local: #{local_version}" unless version > local_version
  return version
end

def change_podspec_version version
  podspec_content = File.read(File.join($podspec_name))
  File.open($podspec_name, "w") do |file|
    file.puts podspec_content.gsub($podspec_version_regex) { |m|
      m.gsub($2, version)
    }
  end
end

def main
  version = get_version

  release_branch = "release/v#{version}"

  run_cmd "git checkout -b #{release_branch}"

  # Update podspec version
  change_podspec_version version

  run_cmd "git add #{$podspec_name}"
  run_cmd "git commit -m 'Bump version to #{release_branch}'"
  run_cmd "git checkout main"
  run_cmd "git pull"
  run_cmd "git merge #{release_branch} --no-ff --no-commit"
  run_cmd "git push"
  run_cmd "git tag -a #{version} -m 'Bump version'"
  run_cmd "git push origin #{version}"
  run_cmd "git checkout develop"
  run_cmd "git merge #{release_branch} --no-ff --no-commit"
  run_cmd "git push"
  run_cmd "git branch -D #{release_branch}"

  puts "\n\n"
  puts '👏👏👏👏👏👏 -Done- 👏👏👏👏👏👏'
end

main