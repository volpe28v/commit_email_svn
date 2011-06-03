require 'kconv'
require 'date'

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

