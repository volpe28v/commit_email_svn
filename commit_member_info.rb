###############################################################################################
# コミットメール配信メンバー情報
###############################################################################################
$:.unshift File.dirname(__FILE__)
require "setting"

# コミット名取得
def getNameFrom( svn_name )

  #Todo: setting.rb に NameList の定義を外だしているが汚いので直す予定

  # 更新者名変換
  commit_name = NameList[svn_name];
  if commit_name == "" then
    commit_name = svn_name;
  end

  return commit_name
end

# コミットメール配信先取得
def getSendMember (repos, isTestMode)

  #Todo: setting.rb に ToAddrs の定義を外だししているが汚いので直す予定

  #コミットメール振り分け設定  
  repo_base_name = repos.split("/")[-1]

  return ToAddrs[repo_base_name]
end

