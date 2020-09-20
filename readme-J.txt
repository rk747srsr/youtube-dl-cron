名前: youtube-dl-cron.sh


概要: 指定したYouTubeチャンネルの更新された動画を保存するシェルスクリプト


説明:

youtube-dl-cron.shは

1. 指定したYouTubeチャンネルの動画IDリストをローカルに保持
2. YouTube上の動画IDリストを取得

1.と2.を比較して、1.に無いIDの動画を更新動画として保存します

cronに

 3 23  *  *  *  youtube-dl-cron.sh チャンネル

と登録しておけば、毎日23時3分にチャンネルをチェックして
更新があれば動画を保存します

! MacOS 10.15でcronを動作させる場合は
  システム環境設定 -> セキュリティとプライバシー -> フルディスクアクセスに
  `/usr/sbin/cron'を追記してください


必要なコマンド:

youtube-dl-cron.shの動作には、以下のコマンドが必要です
! 基本コマンドの他、nkfやperl5等、
　最初からインストールされている可能性が高いものは省略

作者が使用しているヴァージョンを併記します

bash4
  GNU bash 4.3.30(1)
  ! ver.4.3以前や、ver.5、zshは未検証

youtube-dl最新版

python、youtube-dlが要求する以上のヴァージョン
  3.8.2

wget、httpsが有効になっているもの
  1.20
  -cares +digest -gpgme +https +ipv6 -iri +large-file -metalink -nls 
  +ntlm +opie -psl +ssl/openssl 

curl、httpsが有効になっているもの
  7.38.0
  libcurl/7.38.0 OpenSSL/1.0.1t zlib/1.2.8 libidn/1.29 libssh2/1.4.3 librtmp/2.3
  Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s
             rtmp rtsp scp sftp smtp smtps telnet tftp 
  Features: AsynchDNS IDN IPv6 Largefile GSS-API SPNEGO NTLM NTLM_WB SSL libz TLS-SRP 

grep、`-P'オプション(perl正規表現)が有効になっているもの、又はpcregrep
  GNU grep 2.20、pcregrep 8.44
  ! pcregrepを使用する場合は、スクリプト内の`grep -Po'を`pcregrep -o'に置換してください
  * 以下のコマンドでエラーが出なければ`-P'オプションは有効になっています
    grep --help | grep -Po '(?<=(he.|ay |r N)).+?(?=(ON| wo|rsi|sage))'

ffmpeg、opensslが有効になっているもの
  3.4.6
  configuration: --enable-openssl --enable-libxml2 --enable-libmp3lame

足りないコマンドは、aptやbrew、又はビルドして、インストールしてください


youtube-dl-cron.sh内の設定:

youtube-dl-cron.shの以下の部分を環境に合わせて設定してください

tmpdir=       YouTube Liveを録画するときの一時ファイルを保存するパス
              通常は`/tmp'

vartmpdir=    以下のファイルを保存するパス
              ・動画IDリストファイル(youtube_チャンネルID_cache)
              ・エイリアス設定ファイル(youtube_aliases)
              ・キーワードを登録したファイル(youtube_チャンネルID_filter)
              `/var/tmp'等、再起動で中のファイルが消えない場所を指定

outdir=       動画のデフォルト出力先
              `$HOME/Downloads'等
              `-o'オプションで都度変更可能

nkf='nkf ..'  nkfのオプション設定
              `nkf -Z1'(2バイトの英数とスペースを1バイトへ変換)以外は任意

omch=         チャンネルを省略したときに設定されるチャンネル

omchinfo=     $omchの1ワード説明


インストール:

youtube-dl-cron.shに実行権を与えて
  chmod 755 youtube-dl-cron.sh

`/usr/local/bin'、`$HOME/bin'等、パスが通っているディレクトリへコピー
  cp youtube-dl-cron.sh /パスが/通っている/ディレクトリ/


設定ファイル:

$vartmpdir/youtube_チャンネルID_cache
  動画IDリストを保持するファイル
  youtube-dl-cron.sh -U チャンネル
  で生成
  更新が無くても、ダウンロードを実行すると更新されます

$vartmpdir/youtube_aliases
  覚えやすいワードとチャンネルIDを紐付けする設定ファイル
  書式: ワード=channel/チャンネルID

$vartmpdir/youtube_チャンネルID_filter
  保存したい動画にヒットするキーワードを登録したファイル
  書式: 1キーワード1行


使用方法:

  ダウンロード:  youtube-dl-cron.sh チャンネル -i --filter=キーワード|FILE -o ファイル名

    チャンネル
        channel/チャンネルID、user/ユーザー名
        又は、$vartmpdir/youtube_aliasesで設定したエイリアス
        * チャンネルがエラー、又は省略した場合、$omchが設定されます

    -i(省略可能)  動画ページのテキストも保存

    --filter=キーワード(省略可能)
        キーワードにヒットする動画だけ保存
		`FILE'で、キーワードを$vartmpdir/youtube_チャンネル名_filterから読み込みます
        * キーワードは複数設定できます
        * 標準入力では、2ワード目以降はスペースで区切り(--filter=WORD1 WORD2 ..)
        * $vartmpdir/youtube_チャンネル名_filterでは、1ワード1行にしてください

    -o ファイル名(省略可能)
        動画を、ファイル名年日_動画ID.mp4として保存
        /絶対パスのみ/、/絶対パス/ファイル名と指定することも可能

  過去動画をダウンロード:  youtube-dl-cron.sh --ignore-U 本数 チャンネル -i --filter= -o

    --ignore-U 本数
        ローカルに保持しているIDから動画を保存
        本数で、ローカルに保持しているID中、降順に何本保存するか指定
        * 本数を省略した場合、ローカルに保持している中で最新のIDのみダウンロードします

    * -i、--filter=、-oの動作は(通常)ダウンロードとおなじ


  動画IDリストを更新(生成):  youtube-dl-cron.sh -U チャンネル


  チャンネルの動画リストを表示:  youtube-dl-cron.sh -n|N チャンネル

    -n チャンネル
        すべてを表示

    -N チャンネル
        更新分のみ表示


  ヘルプ:  -h


  YouTube Liveを録画:  youbue-dl-cron.sh --live|-r 動画ID -t 分

  ! このオプションはテスト中です

  ! このオプションを短期間に何回も使用すると、YouTubeに対する攻撃と判断されて
    そのとき使用していたIPアドレスではYouTubeにアクセスできなくなります
    アクセスできなくなった場合は、ルーターの再起動等でIPアドレスを変更してください

  ! ほとんどの場合、パケットロスや録画そのものを失敗します

    録画ID
        watch?v=id、又は、id

    -t 分
        録画する時間を分で指定
        `0'を指定した場合、番組終了まで録画(最大24時間)
        ! 録画停止まで、指定した分の数倍の時間が掛かります
