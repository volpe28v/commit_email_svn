$:.unshift File.dirname(__FILE__)

require 'net/smtp'
require 'kconv'
require 'date'

require 'commit_member_info'
require 'setting'
require 'commit_info'

RANK_FILE = File.dirname(__FILE__) + '/commit_ranking.txt';
MAX_COMMIT_POINT = 10

class CommitRank
  def initialize(rank_file = RANK_FILE)
    @rank_file = rank_file
    @commit_info_hash = Hash.new()

    open( rank_file, "w").close unless File.exist?( rank_file )
    open(rank_file,"r"){ |file|
        file.readlines.each{ |line|
            commit_info = CommitInfo.new(line)
            @commit_info_hash[commit_info.userName] = commit_info
        }
    }
  end

  # カウンタ更新メソッド
  def update_ranking( user_name, point = 1)
    # MAX_COMMIT_POINTポイントを上限とする
    if point > MAX_COMMIT_POINT 
      point = MAX_COMMIT_POINT
    end

    # ユーザ名不明の場合
    if user_name == ""
        user_name = "unknown"
    end

    @commit_info_hash[user_name] ||= CommitInfo.new("0 #{user_name} - 0")

    # 該当ユーザのカウントをインクリメント
    @commit_info_hash[user_name].addCommit(point)

    # 結果をファイルへ書き出す
    open(@rank_file,"w"){ |file|
      commit_info_array = @commit_info_hash.to_a.sort{|a,b| (b[1].allCommitNum <=> a[1].allCommitNum) }
      commit_info_array.each{ |commit_info|
        file.puts(commit_info[1].printStr)
        puts commit_info[1].printStr 
      }
    }
  end

  # ランク結果表示文字列作成
  def make_rank_result
    rank_array = self.get_sorted_commit_info_array
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

def make_rank_part( user_name )
    rank_array = self.get_sorted_commit_info_array
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

  def get_rank_num( user_name )
    rank_array = self.get_sorted_commit_info_array
    rank_array.each_with_index {|commit_info,num|
      if commit_info[0] == user_name
        return (num + 1).to_s
      end
    } 

    return "--"
  end

  def get_sorted_commit_info_array
    @commit_info_hash.to_a.sort{|a,b| (b[1].allCommitNum <=> a[1].allCommitNum) }
  end

end

