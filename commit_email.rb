#!/usr/local/bin/ruby -Ke

$:.unshift File.dirname(__FILE__)

require 'net/smtp'
require 'kconv'
require 'date'

require 'commit_member_info'
require 'setting'
require 'mail_sender'

###############################################################################
# 設定値
TEST_MODE = false   # テストモード(メール通知先限定)の場合は true
#TEST_MODE = true   # テストモード(メール通知先限定)の場合は true

# for setting
MAX_COMMIT_POINT = 10
RANK_FILE = File.dirname(__FILE__) + '/commit_ranking.txt';


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
# コミット情報管理クラス
class CommitInfo
    attr_reader :userName
    attr_reader :allCommitNum
    attr_reader :lastCommitDay
    attr_reader :lastCommitDayNum

    def initialize (user_info_text)
       user_info = user_info_text.split(nil)
       @allCommitNum     = user_info[0].to_i
       @userName         = user_info[1]
       @lastCommitDay    = user_info[2]
       @lastCommitDayNum = user_info[3].to_i
    end

    def addCommit( pt )
        @allCommitNum += pt
        if @lastCommitDay == Date.today.to_s
            @lastCommitDayNum += pt
        else
            @lastCommitDay = Date.today.to_s
            @lastCommitDayNum = pt
        end
    end
                                                                                                             
    def todayCommit
        if @lastCommitDay == Date.today.to_s
            return @lastCommitDayNum
        else
            return 0
        end
    end

    def printStr
        return sprintf("%5s %-10s %10s %5s",@allCommitNum.to_s , @userName , @lastCommitDay , @lastCommitDayNum.to_s)
    end
end


###############################################################################
# カウンタ更新メソッド
def update_ranking( user_name, rank_file = RANK_FILE, point = 1)
    # MAX_COMMIT_POINTポイントを上限とする
    if point > MAX_COMMIT_POINT 
      point = MAX_COMMIT_POINT
    end

    commit_info_hash = Hash.new()
    open( rank_file, "w").close unless File.exist?( rank_file )
    open(rank_file,"r"){ |file|
        file.readlines.each{ |line|
            commit_info = CommitInfo.new(line)
            commit_info_hash[commit_info.userName] = commit_info
        }
    }

    # ユーザ名不明の場合
    if user_name == ""
        user_name = "unknown"
        # ランキング定法をそのまま   
        return commit_info_hash.to_a.sort{|a,b| (b[1].allCommitNum <=> a[1].allCommitNum)*2 + (a[0] <=> b[0]) }
    end

    # リストにないメンバーの場合
    if commit_info_hash[user_name] == nil
        commit_info_hash[user_name] = CommitInfo.new("0 #{user_name} - 0")
    end

    # 該当ユーザのカウントをインクリメント
    commit_info_hash[user_name].addCommit(point)

    # ハッシュを回数の多い順に並び換える
#    commit_info_array = commit_info_hash.to_a.sort{|a,b| (b[1].allCommitNum <=> a[1].allCommitNum)*2 + (a[0] <=> b[0]) }
    commit_info_array = commit_info_hash.to_a.sort{|a,b| (b[1].allCommitNum <=> a[1].allCommitNum) }

    # 結果をファイルへ書き出す
    open(rank_file,"w"){ |file|
        commit_info_array.each{ |commit_info|
            file.puts(commit_info[1].printStr)
            print commit_info[1].printStr + "\n"
        }
    }

    return commit_info_array
end

###############################################################################
# ランク結果表示文字列作成
def make_rank_result( rank_array )
    bar_limit = 50
    max_sum = 0
    sum = 0
    rank_array.each{|rank| sum += rank[1].allCommitNum}

    max_sum = (bar_limit * sum) / rank_array[0][1].allCommitNum

    result_array = []
    rank_array.each_with_index{|rank,i|
        rank_mark = "#"
        user_name = rank[0]
        if user_name == "unknown"
           user_name = "orz"   # がっかり変換
           rank_mark = "&"     # 体育座り変換
        end
        rank_bar = rank_mark * (max_sum * rank[1].allCommitNum / sum)
        result_array.push(sprintf("%2s: %-14s Today:%3s All:%5s:%-s\n",
                                  (i+1).to_s, 
                                  user_name, 
                                  rank[1].todayCommit, 
                                  rank[1].allCommitNum, 
                                  rank_bar))
    }
                                                                                                                                               
    return result_array.join
end

def make_rank_part( rank_array , user_name )
    result_array = []
    
    user_index = 0
    rank_array.each_with_index{ |rank,i|
        if user_name == rank[0]
            user_index = i
        end
    }

    rank_array.each_with_index{ |rank,i|
        user_diff = rank[1].allCommitNum - rank_array[user_index][1].allCommitNum 

        if user_diff > 0
            user_diff = '+' + user_diff.to_s
        elsif user_diff == 0
            user_diff = '---'
        end

        result_array.push(sprintf("%2s: %-14s Today:%3s All:%5s  %5s\n",
                                  (i+1).to_s,
                                  rank[0],
                                  rank[1].todayCommit,
                                  rank[1].allCommitNum,
                                  user_diff))
                                  
    }
       
    if result_array.size > 2 
      if user_index == 0
        result_array = result_array[0..1]
      elsif user_index == (result_array.size - 1)
        result_array = result_array[(user_index-1)..user_index]
      else
        result_array = result_array[(user_index-1)..(user_index+1)]
      end
    end

    return result_array.join
end

def get_rank_num( user_name ,rank_file = RANK_FILE )
    open(rank_file,"r"){ |file|
        file.readlines.each_with_index{ |line, num|
            commit_info = CommitInfo.new(line)
            if commit_info.userName == user_name
              return (num + 1).to_s
            end
        }
    }
    return "--"
end

###############################################################################
# メインフロー開始

# 宛先判定
toaddr = getSendMember( REPOS, svnchanged, TEST_MODE )

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

# 上限値チェック
if commit_point > MAX_COMMIT_POINT
  commit_point = MAX_COMMIT_POINT
end

# コミットランキング更新
rank_result_array = update_ranking(svnauthor, RANK_FILE, commit_point);
rank_result =  make_rank_result( rank_result_array )

rank_part = make_rank_part( rank_result_array, svnauthor )

# 更新ファイルのフルパス生成
change_fullpath = []
svnchanged.split("\n").each{ | change_path |
  change_fullpath.push( "#{change_path.split(" ")[0]} #{REPOS}/#{change_path.split(" ",2)[1]}" )
}

# 更新者名変換
commit_name = getNameFrom( svnauthor )

# ランキング取得
rank_num = get_rank_num( svnauthor )

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

