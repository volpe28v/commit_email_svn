#!/usr/local/bin/ruby -Ke

$:.unshift File.dirname(__FILE__)

require 'net/smtp'
require 'kconv'
require 'date'

class CommitMailBody

  def get_hello 
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
  end

  def get_mail_body( elem_hash )
###############################################################################
# メール body 作成
    body = <<-EOB
To: コミッターのみなさま

#{self.get_hello} Subversion です。

#{elem_hash[:commit_name]}さん(#{elem_hash[:rank_num]}位)が #{elem_hash[:update_point]} コミット(#{elem_hash[:commit_point]}pt)しました。
#{elem_hash[:notice]}

#{elem_hash[:rank_part]}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■コミットコメント
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#{elem_hash[:commit_com]}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■詳細情報: [U:修正，A:追加，D:削除]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--------------------------------------------------------
#{elem_hash[:change_fullpath].join("\n")}
--------------------------------------------------------

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■コミット情報
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 リポジトリ: #{elem_hash[:repos]}
 リビジョン: #{elem_hash[:rev]}
 更新者    : #{elem_hash[:commit_name].ljust(47)}
 更新日時  : #{elem_hash[:svndate].ljust(46)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■コミットランキング
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#{elem_hash[:rank_result]}
now commit : #{elem_hash[:svnauthor]}

EOB
  end
end

