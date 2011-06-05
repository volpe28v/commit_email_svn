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

  describe "addCommit" do
    describe "同日のコミットが存在する場合" do
      before do
        @commit_info = CommitInfo.new("5 naoki #{Date.today.to_s} 2")
        @commit_info.addCommit(10)
      end
      context "allCommitNum" do
        subject{ @commit_info }
        it { subject.allCommitNum.should == 15 }
      end
      context "todayCommit" do
        subject{ @commit_info }
        it { subject.todayCommit.should == 12 }
      end
    end

    describe "同日のコミットが存在しない場合" do
      before do
        @commit_info = CommitInfo.new("5 naoki #{(Date.today - 1).to_s} 0")
        @commit_info.addCommit(10)
      end
      context "allCommitNum" do
        subject{ @commit_info }
        it { subject.allCommitNum.should == 15 }
      end
      context "todayCommit" do
        subject{ @commit_info }
        it { subject.todayCommit.should == 10 }
      end
    end
    describe "連続してコミットした場合(10,5)" do
      before do
        @commit_info = CommitInfo.new("5 naoki #{(Date.today - 1).to_s} 0")
        @commit_info.addCommit(10)
        @commit_info.addCommit(5)
      end
      context "allCommitNum" do
        subject{ @commit_info }
        it { subject.allCommitNum.should == 20 }
      end
      context "todayCommit" do
        subject{ @commit_info }
        it { subject.todayCommit.should == 15 }
      end
    end
  end
end



