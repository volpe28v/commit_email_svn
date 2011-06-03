#!/usr/local/bin/ruby -Ke

$:.unshift File.dirname(__FILE__)

require 'net/smtp'
require 'kconv'
require 'date'

require 'commit_member_info'
require 'setting'
require 'mail_sender'
require 'commit_rank'

###############################################################################
# 設定値
TEST_MODE = false   # テストモード(メール通知先限定)の場合は true
#TEST_MODE = true   # テストモード(メール通知先限定)の場合は true

REPOS = ARGV[0]
REV   = ARGV[1].to_i

# SVN更新情報取得
svnauthor  =%x{svnlook author #{REPOS} -r #{REV}}.chomp
svndate    =%x{svnlook date #{REPOS} -r #{REV}}.chomp
svnchanged =%x{svnlook changed #{REPOS} -r #{REV}}.chomp
svnlog     =%x{svnlook log #{REPOS} -r #{REV}}.chomp
#svndiff    =%x{svnlook diff #{REPOS} -r #{REV}}.chomp

svnlog = svnlog.kconv(Kconv::EUC, Kconv::ASCII)

fromaddr=['Subversion@localhost.localdomain']

###############################################################################
# メインフロー開始

# 宛先判定
toaddr = getSendMember( REPOS,TEST_MODE )

update_point = svnchanged.split("\n").length

# コミットコメント変換
commit_com = svnlog;
commit_point = update_point
notice = ""
if commit_com == "" then
    commit_com = "なし"
    commit_point = 0 
    notice = "※コミットコメントが未記述な場合はポイント加算されません。"
end

# コミットランキング更新
commit_rank = CommitRank.new
commit_rank.update_ranking(svnauthor, commit_point);
rank_result =  commit_rank.make_rank_result

rank_part = commit_rank.make_rank_part(svnauthor )

# 更新ファイルのフルパス生成
change_fullpath = []
svnchanged.split("\n").each{ | change_path |
  change_fullpath.push( "#{change_path.split(" ")[0]} #{REPOS}/#{change_path.split(" ",2)[1]}" )
}

# 更新者名変換
commit_name = getNameFrom( svnauthor )

# ランキング取得
rank_num = commit_rank.get_rank_num( svnauthor )

# コミットファイル情報取得
update_filename = svnchanged.split("\n")[0].split(" ")[1]

# 挨拶選択
now_time = Time.now

hello = ""
case now_time.hour
when 8..10
  hello = "おはようございます!"
when 11..16
  hello = "こんにちは!"
when 17..21
  hello = "こんばんは!"
when 22..24
  hello = "遅くまでご苦労様です。"
when 0..4
  hello = "かなり遅くまでご苦労様です。"
when 5..7
  hello = "朝早くからご苦労様です。"
else
  hello = "お疲れさまです。"
end

###############################################################################
# メール body 作成
body = <<-EOB
To: コミッターのみなさま

#{hello} Subversion です。

#{commit_name}さん(#{rank_num}位)が #{update_point} コミット(#{commit_point}pt)しました。
#{notice}

#{rank_part}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■コミットコメント
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#{commit_com}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■詳細情報: [U:修正，A:追加，D:削除]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--------------------------------------------------------
#{change_fullpath.join("\n")}
--------------------------------------------------------

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■コミット情報
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 リポジトリ: #{REPOS}
 リビジョン: #{REV}
 更新者    : #{commit_name.ljust(47)}
 更新日時  : #{svndate.ljust(46)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■コミットランキング
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#{rank_result}
now commit : #{svnauthor}

EOB

###############################################################################
# メールヘッダ作成

# コミットコメントの一行目をサブジェクトに表示する
update_log = svnlog;
if update_log != ""
   update_log = " : #{update_log.split("\n")[0].to_s}";
end

subject = " #{commit_name}さんがコミットしました [#{File.basename(update_filename)} (#{update_point})] #{update_log}"
repo_name = File.basename(REPOS);

g_sub = "[SVN-#{repo_name}-#{REV}] #{subject.tojis}"
g_body = body.tojis
GmailSender.new(MyGmailAddr, MyGmailPass).send_mail( g_sub, g_body, fromaddr, toaddr)

exit

