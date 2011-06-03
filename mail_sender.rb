require 'kconv'
require 'nkf'
require 'rubygems'
require 'tmail'
require 'tlsmail'

class MailSender
  def initialize( smtp, port, id = nil , pass = nil )
    @id   = id
    @pass = pass
    @smtp = smtp
    @port = port
  end

  def send_mail(subject, body, from, to )
    mail                   = TMail::Mail.new
    mail.to                = to
    mail.from              = from
    mail.subject           = NKF.nkf("-WMm0", subject.kconv(Kconv::JIS, Kconv::UTF8) )
    mail.date              = Time.now
    mail.mime_version      = '1.0'
    mail.transfer_encoding = '7bit'
    mail.set_content_type 'text', 'plain', {'charset'=>'iso-2022-jp'}
    mail.body              = body.kconv(Kconv::JIS, Kconv::UTF8)

    self.before_send_hook
    Net::SMTP.start( @smtp,  @port , "localhost.localdomain", @id, @pass, "plain"){ |smtp|
      smtp.sendmail(mail.encoded, mail.from, *mail.to)
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

