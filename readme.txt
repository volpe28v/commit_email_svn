[ruby]
1.8.7以上で動作確認済み

[gemライブラリ]
tmail
tlsmail

[使い方]
setting.rb.default を setting.rb として設定を書いてください
post-commit をリポジトリの hooks/ に置いてください
post-commit に記述されている commit_mail.rb へのパスは環境に合わせて変更してください

デフォルトではGmailのSMTPを使うように設定してあります。
任意のSMTPを指定したい場合は commit_email.rb の最後辺りを適当にいじってください。
(そのうち良い仕組み考えます)
