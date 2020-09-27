名前: youtube-dl-cron.sh


概要: 指定したYouTubeチャンネルの更新された動画を保存するシェルスクリプト


説明:
youtube-dl-cron.shは、指定したYouTubeチャンネルの(過去チェックした時点の)動画IDリストをローカルに保持、YouTube上の(今チェックした時の)動画IDリストと比較して、ローカルに無いIDの動画を更新動画として、更新動画を自動保存するスクリプトです

cronに` 3 23  *  *  *  youtube-dl-cron.sh チャンネル'と登録しておけば、毎日23時3分にチャンネルをチェックして、更新があれば動画を保存します
! MacOS 10.15でcronを動作させる場合は、システム環境設定→セキュリティとプライバシー→フルディスクアクセスに`/usr/sbin/cron'を追記してください

* スクリプトがほぼ同じnico-dl-cron.shについても、このreadme-J.txtの末尾で触れます
! ニコ生、タイムシフトの保存はできません


必要なコマンド:
youtube-dl-cron.shの動作には、以下のコマンドが必要です
! 基本コマンドの他、nkfやperl5等、最初からインストールされている可能性が高いものも省略
作者が使用しているヴァージョンを併記します

 bash4
GNU bash 4.3.30(1)
! ver.4.3以前や、ver.5、zshは未検証

 youtube-dl最新版

 python、youtube-dlが要求する以上のヴァージョン
3.8.2

 wget、httpsが有効になっているもの
1.20
+digest +https +ipv6 +large-file +ntlm +opie +ssl/openssl 

 curl、httpsが有効になっているもの
7.38.0
libcurl/7.38.0 OpenSSL/1.0.1t zlib/1.2.8 libidn/1.29 libssh2/1.4.3 librtmp/2.3
Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtmp rtsp scp sftp smtp smtps telnet tftp 
Features: AsynchDNS IDN IPv6 Largefile GSS-API SPNEGO NTLM NTLM_WB SSL libz TLS-SRP 

 grep、-Pオプション(PERL正規表現)が有効になっているもの、又はpcregrep
GNU grep 2.20、pcregrep 8.44
! pcregrepを使用する場合は、スクリプト内の`grep -Po'を`pcregrep -o'に置換してください
以下のコマンドでエラーが出なければ、Pオプションは有効になっています
grep --help | grep -Po '(?<=(he.|ay |r N)).+?(?=(ON| wo|rsi|sage))'

ffmpeg、opensslが有効になっているもの
3.4.6
configuration: --enable-openssl --enable-libxml2 --enable-libmp3lame

足りないコマンドは、aptやbrew又はビルドして、インストールしてください


youtube-dl-cron.sh内の設定:
youtube-dl-cron.shの以下の部分を環境に合わせて設定してください

 tmpdir=
YouTube Liveを録画するときの一時ファイルを保存するパス。`/tmp'等

 vartmpdir=
動画IDリストファイル(youtube_チャンネルID_cache)、エイリアス設定ファイル(youtube_aliases)、キーワードを登録したファイル(youtube_チャンネルID_filter)を保存するパス。`/var/tmp'等、再起動で中のファイルが消えない場所を指定

 outdir=
動画のデフォルト出力先。`$HOME/Downloads'等
* oオプションで都度変更可能

 nkf='nkf Z1 ..'
nkfのオプション設定
`nkf -Z1(2バイトの英数とスペースを1バイトへ変換)'以外は任意

 omch=
チャンネルを省略したときに設定されるチャンネル

 omchinfo=
omchの1ワード説明


インストール:
youtube-dl-cron.shに実行権を与えて(chmod 755 youtube-dl-cron.sh)、`/usr/local/bin'、`$HOME/bin'等、パスが通っているディレクトリへコピー(cp youtube-dl-cron.sh /パスが/通っている/ディレクトリ/)


設定ファイル:

 vartmpdir/youtube_チャンネルID_cache
動画IDリストを保持するファイル
新規作成、更新: youtube-dl-cron.sh -U チャンネルID
* ダウンロードを実行しても更新されます

 vartmpdir/youtube_aliases
覚えやすいワードとチャンネルIDを紐付けする設定ファイル
書式: ワード=channel/チャンネルID

 vartmpdir/youtube_チャンネルID_filter
保存したい動画にヒットするキーワードを事前に登録するファイル
書式: 1キーワード1行


使用方法:

 ダウンロード:  youtube-dl-cron.sh チャンネル
必須:
 チャンネル
channel/チャンネルID、user/ユーザー名、又は、vartmpdir/youtube_aliasesで設定したエイリアス
* チャンネルがエラー、又は省略した場合、omchが設定されます
任意:
 -i
動画ページのテキストも保存
 --filter=キーワード
キーワードにヒットする動画だけ保存
`FILE'で、キーワードをvartmpdir/youtube_チャンネル名_filterから読み込みます
* キーワードは複数設定可。標準入力では2ワード目以降はスペースで区切り(--filter=WORD1 WORD2 ..)、vartmpdir/youtube_チャンネル名_filterでは1ワード1行にしてください
 -o /ディレクトリ/ファイル名
動画を、ファイル名年日_動画ID.mp4として保存。/絶対パスのみ/、/絶対パス/ファイル名と指定することも可能

 過去動画をダウンロード:  youtube-dl-cron.sh --ignore-U 本数 チャンネル
必須:
 --ignore-U 本数
ローカルに保持しているIDから動画を保存
本数で、ローカルに保持しているID中、新しい順に何本保存するか指定
* 本数を省略した場合、ローカルに保持している中で最新のIDのみダウンロードします
任意:
 -i
 --filter=キーワード
 -o /ディレクトリ/ファイル名

 動画IDリストを更新(生成):  youtube-dl-cron.sh -U チャンネル

 チャンネルの動画リストを表示:  youtube-dl-cron.sh -n|N チャンネル
 -n チャンネル
すべてを表示
 -N チャンネル
更新分のみ表示

 ヘルプ:  youtube-dl-cron.sh -h


使用方法(nico-dl-cron.sh):

 ダウンロード:  nico-dl-cron.sh チャンネル
 過去動画をダウンロード:  nico-dl-cron.sh --ignore-U 本数 チャンネル
 動画IDリストを更新(生成):  nico-dl-cron.sh -U チャンネル
 チャンネルの動画リストを表示:  nico-dl-cron.sh -n|N チャンネル
 ヘルプ:  nico-dl-cron.sh -h

* ログインの必要が無いアーカイヴのみ対応。ニコ生とタイムシフトは保存できません

ログイン不要で無料視聴できるタイムシフトのみ、以下の方法で保存できます

1. ブラウザでタイムシフトの動画を再生(音声はミュートにした方が好い)
2. 再生したままの状態で、コンソール(Terminal)に、while :; do youtube-dl https://live2.nicovideo.jp/watch/lv数字;  [[ ! `ls *.part` ]] && break; done

* 途中から有料パートが始まる動画の場合、有料部分は黒画面無音になります
! 有料パートが途中から始まる動画でも、保存が終了するまで停止しないでください。途中で停止させると再生できないファイルになります
