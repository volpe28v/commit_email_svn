require 'kconv'
require 'nkf'
require 'rubygems'
require 'tlsmail'

class MailSender
  def initialize( smtp, port, id = nil , pass = nil )
    @id   = id
    @pass = pass
    @smtp = smtp
    @port = port
  end

  def send_mail(subject, body, from, to )
    mailbody = <<EOT
From: #{from}
To: #{to.join(", ")}
Subject: #{NKF.nkf("-WMm0", subject)}
Date: #{Time::now.strftime("%a, %d %b %Y %X %z")}
Mime-Version: 1.0
Content-Type: text/plain; charset=ISO-2022-JP
Content-Transfer-Encoding: 7bit

#{NKF.nkf("-Wjm0", body)}
EOT

    self.before_send_hook
    Net::SMTP.start( @smtp,  @port , "localhost.localdomain", @id, @pass, "plain"){ |smtp|
      smtp.sendmail mailbody, from, *to
    }
  end
  
  def before_send_hook
  end

end

class GmailSender < MailSender
  def initialize( gmail_addr, gmail_pass )
    @id   = gmail_addr
    @pass = gmail_pass
    @smtp = "smtp.gmail.com"
    @port = 587
  end

  def before_send_hook
    Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
  end

end

