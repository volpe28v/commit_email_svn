# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)

require "commit_info"

describe CommitInfo do
  describe "インスタンス化された場合" do
    before do
      @commit_info = CommitInfo.new("0 naoki - 0")
    end
    context "allCommitNum" do
      subject{@commit_info}
      it do
        subject.allCommitNum.should == 0
      end
    end

    context "userName" do
      subject{@commit_info}
      it do
        subject.userName.should == "naoki" 
      end
    end

    context "lastCommitDay" do
      subject{@commit_info}
      it do
        subject.lastCommitDay.should == "-" 
      end
    end

    context "lastCommitDayNum" do
      subject{@commit_info}
      it do
        subject.lastCommitDayNum.should == 0 
      end
    end
  end

end



