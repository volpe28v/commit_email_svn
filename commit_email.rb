#!/usr/local/bin/ruby -Ke
# -*- coding: utf-8 -*-

$:.unshift File.dirname(__FILE__)

require 'net/smtp'
require 'kconv'
require 'date'

require 'commit_member_info'
require 'setting'
require 'mail_sender'
require 'commit_rank'
require 'mail_body'
require 'svnlook_result'

###############################################################################
# 設定値

REPOS = ARGV[0]
REV   = ARGV[1].to_i

# SVN更新情報取得
svn = SvnlookResult.new(REPOS, REV)
svnauthor  = svn.author
svndate    = svn.date
svnchanged = svn.changed
svnlog     = svn.log

fromaddr=['Subversion@localhost.localdomain']

###############################################################################
# メインフロー開始

# 宛先判定
toaddr = getSendMember( REPOS )

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

body = CommitMailBody.new.get_mail_body(
  {:commit_name => commit_name,
   :commit_point => commit_point,
   :commit_com => commit_com,
   :update_point => update_point,
   :notice => notice,
   :rank_num => rank_num,
   :rank_part => rank_part,
   :rank_result => rank_result,
   :change_fullpath => change_fullpath,
   :repos => REPOS,
   :rev => REV,
   :svndate => svndate,
   :svnauthor => svnauthor,
  })


# コミットコメントの一行目をサブジェクトに表示する
update_log = svnlog;
if update_log != ""
   update_log = " : #{update_log.split("\n")[0].to_s}";
end

subject = " #{commit_name}さんがコミットしました [#{File.basename(update_filename)} (#{update_point})] #{update_log}"
repo_name = File.basename(REPOS);

sub = "[SVN-#{repo_name}-#{REV}] #{subject}"
GmailSender.new(MyGmailAddr, MyGmailPass).send_mail( sub, body, fromaddr, toaddr)

#Gmail以外で 任意のSMTP を指定して送る場合は、上記をコメントアウトして
#代わりに以下を有効にしてください
#MailSender.new(SmtpAddr ,SmtpPort).send_mail( sub, body, fromaddr, toaddr)

exit

