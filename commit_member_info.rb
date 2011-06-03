###############################################################################################
# コミットメール配信メンバー情報
#   コミットメール配信メンバーを追加する場合は下記に追加してください。
#    1.ユーザ名変換テーブルに、アカウント名とユーザ名を登録する(メールの題名などで表示されます)
#    2.コミットメール配信先にメールアドレスを登録(グループがなければ新規に作成する)
#    3.コミットメール振り分けを編集(新規にコミットメール配信グループを作成した場合)
###############################################################################################
$:.unshift File.dirname(__FILE__)
require "setting"

# コミット名取得
def getNameFrom( svn_name )

###############################################################################################
# 1.ユーザ名変換テーブル登録

#Todo: setting.rb で NameList を定義しているが汚いので直す予定

# 更新者名変換
commit_name = NameList[svn_name];
if commit_name == "" then
  commit_name = svn_name;
end

  return commit_name
end

# コミットメール配信先取得
def getSendMember (repos, svnchanged ,isTestMode)

###############################################################################################
# 2.コミットメール配信先を設定する(必要であればグループごと新規追加する)

#Todo: setting.rb で ToAddrs を定義しているが汚いので直す予定

###############################################################################################
# 3.コミットメール振り分け設定(グループを新規追加した場合)  
repo_base_name = repos.split("/")[-1]

  return ToAddrs[repo_base_name]
end

