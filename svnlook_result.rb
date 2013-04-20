require 'kconv'

class SvnlookResult
    attr_reader :author, :date, :changed, :log

    def initialize(repos, rev)
      if RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|cygwin|bccwin/
        get_result_for_win(repos, rev)
      else
        get_result_for_linux(repos, rev)
      end
    end

    private

    def get_result_for_win(repos, rev)
        @author  = %x{svnlook author #{repos} -r #{rev}}.chomp.kconv(Kconv::UTF8, Kconv::SJIS)
        @date    = %x{svnlook date #{repos} -r #{rev}}.chomp.kconv(Kconv::UTF8, Kconv::SJIS)
        @changed = %x{svnlook changed #{repos} -r #{rev}}.chomp.kconv(Kconv::UTF8, Kconv::SJIS)
        @log     = %x{svnlook log #{repos} -r #{rev}}.chomp.kconv(Kconv::UTF8, Kconv::SJIS)
    end

    def get_result_for_linux(repos, rev)
        @author  = %x{env LANG=ja_JP.UTF-8 svnlook author #{repos} -r #{rev}}.chomp
        @date    = %x{env LANG=ja_JP.UTF-8 svnlook date #{repos} -r #{rev}}.chomp
        @changed = %x{env LANG=ja_JP.UTF-8 svnlook changed #{repos} -r #{rev}}.chomp
        @log     = %x{env LANG=ja_JP.UTF-8 svnlook log #{repos} -r #{rev}}.chomp
    end
end
