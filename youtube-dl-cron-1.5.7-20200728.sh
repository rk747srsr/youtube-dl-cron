#!/usr/bin/env bash

tmpdir=/tmp
vartmpdir=/var/tmp
outdir=$HOME/Downloads; outdir_def=$outdir
nkf='nkf --fb-skip -m0 -Z1 -Lu'
xmler() {
  sed -E "s/&amp;nbsp;/ /g; s/&(apos|#039);/'/g; s/&(quot|#034);/\"/g; s/(&(amp|#038);|\\\u0026)/\&/g; s/&lt;/</g; s/&gt;/>/g"
}
omch=user/IKCTV
omchinfo=iiizu
ver=1.5.7-20200728

usage() {
  echo "youtube-dl-cron.sh($ver): cron utility for youtube-dl"
  echo 'download:'
  echo '  <ch> (-i) (--filter=wd|FILE) (-o outname1 ..)'
  echo '  --ignore-U (nr) <ch> (-i) (--filter=) (-o ..)'
  echo "   ch:channel/xxx user/xxx alias($vartmpdir/youtube_aliases)"
  echo "      omitted:${omch}($omchinfo)"
  echo '   -i:info'
  echo "   --filter=FILE:from $vartmpdir/youtube_xxx_filter"
  echo '   -o:outname'
  echo '   --ignore-U:ignore updates'
  echo '   nr:to go back'
  echo 'cache update:'
  echo '  -U <ch>'
  echo 'updates:'
  echo '  -n <ch>'
  echo 'newer:'
  echo '  -N <ch>'
  echo 'help:'
  echo '  -h'
  exit 0
}

url=https://www.youtube.com

alias() {
  [[ $ch && `grep "^${ch}=" $vartmpdir/youtube_aliases` ]] && ch=`grep -Po "(?<=${ch}=).+" $vartmpdir/youtube_aliases`
}

cherr() {
  echo "$$ [error] not found channel=$ch, channel/xxx or user/xxx"
  echo "$$ [error] or alias"
  sed "/^$/d; s/^/$$ [alias] /" $vartmpdir/youtube_aliases 
  echo "$$ [warning] using default($omch)"
  ch=$omch
}

mkcache() {
  [ ! -f "$vartmpdir/youtube_${ch#*/}_cache" ] && touch $vartmpdir/youtube_${ch#*/}_cache
}

case $1 in
  -h)
  usage
  ;;
  -n*|-N*)
  [ ! ${1:2} ] && ch=$2 || ch=${1:2}
  alias
  # set default ch
  [[ ! $ch || ! `echo $ch | grep -E '(channel|user)/'` ]] && cherr
  chsrc=`curl -s $url/$ch/videos | perl -pe 's/}\,/}\n/g'`
  mkcache
  if [ "$1" = '-N' ]; then
    if [ -s $vartmpdir/youtube_${ch#*/}_cache ]; then
      headp=`head -1 $vartmpdir/youtube_${ch#*/}_cache`
      sedp=`echo "$chsrc" | sed -n "/vi\/$headp/=" 2>/dev/null | head -1`
    else
      sedp='$'
    fi
  else
    sedp='$'
  fi
  echo "$chsrc" | sed -n "1,${sedp}"p 2>/dev/null | grep '^"title' | grep -Po '(?<=label":").+(?="})' | xargs -IRET echo -e "RET\n" | tac | sed '1d' | xmler | $nkf
  ;;
  *)
  name=(`echo $* | grep -Po '(?<= -o).+?(?=( -|$))' | tr ' ' '\n' | tac`)
  [[ `echo $* | grep -e ' -i'` ]] && option_i=on
  case $1 in
#   --live|-r)
#   option_r=on
#   if [[ ! ${2:8} || `echo $* | grep -E '(channel|user)/'` ]]; then
#     echo "$$ [error] not id=$2, exit"
#     exit 1
#   fi
#   id=${2#*?v=}
#   mp4=$url'/watch?v='$id
#   # -t option check
#   optarg_t=`echo $* | grep -Po '(?<= -t)[ 0-9]*'`
#   case ${optarg_t/ /} in
#     [0-9]*)
#     [ $optarg_t -gt 0 ] && optarg_t=$(($optarg_t * 60)) || optarg_t=86400
#     ;;
#     *)
#     echo "$$ [error] -t option, set to -t 0"
#     errtzeor='-t 0'
#     optarg_t=86400
#     ;;
#   esac
#   # id conflict check
#   if [ -f "$tmpdir/youtube_${id}.lock" -o "`ls $tmpdir/*${id}*.mp4.part 2>/dev/null`" ]; then
#     echo "$$ [error] `date '+%m-%d %H:%M:%S'` now recording $id, exit"
#     exit 1
#   fi
#   touch $tmpdir/youtube_$id.lock
#   # onair check
#   echo -n "$$ [onair] `date '+%m-%d %H:%M:%S'` standby..."
#   while :
#   do
#     [[ `youtube-dl $mp4 --get-url 2>/dev/null` ]] && break
#     sleep 1
#     standbytime=$(($standbytime + 1))
#     if [[ $standbytime -gt 600 ]]; then
#       echo
#       echo "$$ [warning] standby time 10 minutes elapsed, exit"
#       exit 1
#     fi
#   done
#   echo 'ok'
#   # separate dir name live
#   if [ $name ]; then
#     if [[ `echo $name | grep '/'` ]]; then
#       outdir=${name%/*}
#       [ ! -e $outdir ] && mkdir -p $outdir
#     fi
#     if [ ${name: -1} != '/' ]; then
#       name=${name##*/}`date +%Y%m%d`'-LIVE_'$id
#     else
#       name=$id'_'`date +%Y%m%d-%H%M`
#     fi
#   else
#     name=$id'_'`date +%Y%m%d-%H%M`
#   fi
#   recdl=rec; stopsuccess='stop'
#   dates_start=`date +%s`
#   datedonedays=`date -d 1day +%s`
#   ;;
    *)
    # download option check
    case $1 in
      -U*)
      option_U=on
      [ ! ${1:2} ] && ch=$2 || ch=${1:2}
      ;;
      --ignore-[Uu])
      option_U=off
      if [ $3 ]; then
        expr $2 + 1 >/dev/null 2>&1
        case $? in
          0)
          [[ ${2: 0:1} == '-' ]] && optarg_iU=${2: 1} || optarg_iU=$2
          ch=$3
          ;;
          *)
          optarg_iU=1
          ch=`echo $* | grep -Po '(?<= )(channel|user)/.+?(?=( |$))'`
          [[ ! $ch && $(echo $* | tr ' ' '|' | xargs -IALIAS grep -E "^(ALIAS)=" $vartmpdir/youtube_aliases) ]] && ch=$(grep -Po "^($(echo $* | tr ' ' '|'))(?=\=)" $vartmpdir/youtube_aliases)
          ;;
        esac
      else
        optarg_iU=1
        ch=$2
      fi
      ;;
      *)
      ch=$1
      ;;
    esac
    [[ `echo $* | grep -e '--filter'` ]] && filter=on
    alias
    # set default ch
    if [[ ! $ch || ${ch: 0:1} == '-' || ! `echo $ch | grep -E '(channel|user)/'` ]]; then
      cherr
      name=$omchinfo
    fi
    chsrc=`curl -s $url/$ch/videos | perl -pe 's/(("title":|]}}]}}))/\n$1/g'`
    # make cache
    chid=(`echo "$chsrc" | grep -Po '(?<=v=).+?(?=",)'`)
    mkcache
    if [[ `cat $vartmpdir/youtube_${ch#*/}_cache` != `echo ${chid[@]} | tr ' ' '\n'` || $option_U ]]; then
      updatech=($(diff $vartmpdir/youtube_${ch#*/}_cache <(echo ${chid[@]} | tr ' ' '\n') | grep -Po '(?<=> ).+'))
      if [ $filter ]; then
        filtering() {
          [ "${#filterwd[@]}" -ge 2 ] && filterwd=`echo ${filterwd[@]} | $nkf | tr ' ' '|'`
          for flt in `seq 0 $((${#updatech[@]} - 1))`
          do
            updatech_flt=(${updatech_flt[@]} $(echo "$chsrc" | $nkf | grep -e "${updatech[$flt]}" | grep -E "($(echo $filterwd | $nkf))" | grep -Po '(?<=v=).+?(?=",)'))
          done
          if [ ! $optarg_iU ]; then
            for upflt in `seq 0 $((${#updatech_flt[@]} - 1))`
            do
              [[ ! `grep ${updatech_flt[$upflt]} $vartmpdir/youtube_${ch#*/}_cache` ]] && updatech_upflt=(${updatech_upflt[@]} ${updatech_flt[$upflt]})
            done
          # filtering ignore-U
          else
            filterwd=(`echo $filterwd | $nkf | tr '|' ' '`)
            for upflt in `seq 0 $((${#filterwd[@]} - 1))`
            do
              updatech_upflt=(${updatech_upflt[@]} $(echo "$chsrc" | $nkf | grep "$(echo ${filterwd[$upflt]} | $nkf)" | grep -Po '(?<=v=).+?(?=",)' | head -$optarg_iU))
            done
          fi
          updatech_flt=(${updatech_upflt[@]})
        }
        filterwd=(`echo $* | grep -Po '(?<=--filter=).*?(?=( -|$))'`)
        case ${filterwd[0]} in
          FILE|`[ ! "$filterwd" ]`)
          if [ -f $vartmpdir/youtube_${ch#*/}_filter ]; then
            filterwd=(`$nkf $vartmpdir/youtube_${ch#*/}_filter`)
            filtering
          else
            unset filter
          fi
          ;;
          *)
          filtering
          ;;
        esac
        [ $filter ] && updatech=(${updatech_flt[@]})
      fi
      # out premiere id
      for prem in `seq 0 $((${#updatech[@]} - 1))`
      do
        [[ `echo "$chsrc" | grep -c "id=\"${updatech[$prem]}"` -ge 2 ]] && premiere=(${premiere[@]} ${updatech[$prem]})
      done
      if [ "$premiere" ]; then
        [ "${#premiere[@]}" -ge 2 ] && premiere=`echo ${premiere[@]} | tr ' ' '|'`
        updatech=(`echo ${updatech[@]} | tr ' ' '\n' | grep -v -E "($premiere)"`)
        chid=(`echo ${chid[@]} | tr ' ' '\n' | grep -v -E "($premiere)"`)
      fi
      # cachefile update
      if [[ ${chid[@]} ]]; then
        cp $vartmpdir/youtube_${ch#*/}_cache $tmpdir/youtube_${ch#*/}_cache.bak
        echo ${chid[@]} | tr ' ' '\n' >$vartmpdir/youtube_${ch#*/}_cache
      fi
      # no update filtering out
      [[ $filter && ! $updatech ]] && echo "`date +'%m-%d %H:%M:%S'` youtube-dl-cron.sh: no update $ch filter=$filterwd" | $nkf && exit 0
      # no update premiere out
      [[ $premiere && ! $updatech ]] && echo "`date +'%m-%d %H:%M:%S'` youtube-dl-cron.sh: no update $ch" && exit 0
      # into updatech ignore-U
      if [ "$option_U" = 'off' ]; then
        if [ ! $filter ]; then
          updatech=(`head -$optarg_iU $vartmpdir/youtube_${ch#*/}_cache`)
        else
          updatech=(${updatech_flt[@]})
        fi
      fi
      # naming
      if [ "$option_U" != 'on' ]; then
        # naming all
        if [[ ${#name[@]} -lt ${#updatech[@]} ]]; then
          for namen in `seq 0 $((${#updatech[@]} - 1))`
          do
            [ ! ${name[$namen]} ] && name[$namen]=${name[$((${#name[@]} - 1))]}
          done 2>/dev/null
        fi
        for upchid in `seq 0 $((${#updatech[@]} - 1))`
        do
          mp4[$upchid]=$url/watch?v=${updatech[$upchid]}
          date=`curl -s ${mp4[$upchid]} | grep -Po '(?<=uploadDate" content=").+(?=">)' | tr -d '-'`
          [[ ! $date ]] && date=`date +%Y%m%d`
          # separate dir name archive
          if [[ ${name[$upchid]} ]]; then
            if [[ `echo ${name[$upchid]} | grep '/'` ]]; then
              outdir[$upchid]=${name[$upchid]%/*}
              [ ! -e ${outdir[$upchid]} ] && mkdir -p ${outdir[$upchid]}
            fi
            if [ ${name[$upchid]: -1} != '/' ]; then
              name[$upchid]=${name[$upchid]##*/}$date'_'${updatech[$upchid]}
            else
              name[$upchid]=${ch##*/}'_'$date'_'${updatech[$upchid]}
            fi
          else
            name[$upchid]=${ch##*/}'_'$date'_'${updatech[$upchid]}
          fi
        done
      fi
    # no update
    else
      echo "`date +'%m-%d %H:%M:%S'` youtube-dl-cron.sh: no update $ch"; exit 0
    fi
    # cache updates only
    [ "$option_U" = 'on' ] && exit 0
    recdl=download; stopsuccess='successful'
    ;;
  esac
  if [ ! $mp4 ]; then
    echo "$$ [error] `date +'%m-%d %H:%M:%S'` not found watch url, exit"
    exit 1
  fi
  # download
  echo "$$ $0 $* $errtzeor"
  echo "$$ [$recdl] `date +'%m-%d %H:%M:%S'` start"
    if [ $option_r ]; then
      # live
      optarg_f=`youtube-dl --list-formats $mp4 | awk '/(best)/{print $1}'`
      youtube-dl -q -f $optarg_f --hls-use-mpegts $mp4 --no-part -o $tmpdir/$name.mp4 2>/dev/null &
      # kill timer
      dursec() {
        ffmpeg -i $tmpdir/$name.mp4 2>&1 | tr ':.' ' ' | awk '/Duration/{print ($2*360) + ($3*60) + $4}'
      }
      psffmpeg() {
        ps x | grep -v grep | grep ffmpeg.*$id
      }
      while :
      do
        sleep 60
        case $optarg_t in
          86400)
          sleep 240
          # dash downloads
          dashcode=`youtube-dl --list-formats $mp4`
          if [[ `echo "$dashcode" | grep 'DASH video'` && ! -f $outdir/${name}_DASH.mp4 ]]; then
            [ ! "$dashdl" ] && echo "$$ [onair] `date '+%m-%d %H:%M:%S'` stop" && dates_stop=`date +%s`
            echo "$$ [backup] `date '+%m-%d %H:%M:%S'` mpeg-dash downloads"
            youtube-dl -q -f `echo "$dashcode" | grep 'mp4_dash' | awk 'END{print $1}'` $mp4 -o $tmpdir/${name}_VIDEO.mp4
            if [[ `name=${name}_VIDEO; dursec; name=${name/_VIDEO}` -ge $(($dates_stop - $dates_start - 300)) ]]; then
              youtube-dl -q -f `echo "$dashcode" | grep 'm4a_dash' | awk 'END{print $1}'` $mp4 -o $tmpdir/${name}_AUDIO.m4a
              ffmpeg -i $tmpdir/${name}_VIDEO.mp4 -i $tmpdir/${name}_AUDIO.m4a -loglevel error -vcodec copy -acodec copy $outdir/${name}_DASH.mp4
              echo "$$ [backup] `date '+%m-%d %H:%M:%S'` successful"
              echo "$$ d`ffmpeg -i $outdir/${name}_DASH.mp4 2>&1 | grep -Po '(?<= D).+(?=\.[0-9]{2},)'`"
            else
              echo "$$ [error] `date '+%m-%d %H:%M:%S'` backup failed"
              rm $tmpdir/${name}_VIDEO.mp4
            fi
            dashdl=on
          fi
          [[ ! `psffmpeg` || `date +%s` -ge $datedonedays ]] && break
          ;;
          *)
          [[ `dursec` -ge $optarg_t || ! `psffmpeg` ]] && break
          ;;
        esac
      done
      # after follow
      kill `psffmpeg | awk '{print $1}'` 2>/dev/null &
      wait
      rm $tmpdir/youtube_$id.lock
      #mv $tmpdir/$name.mp4.part $tmpdir/$name.mp4
      ffmpeg -i $tmpdir/$name.mp4 -loglevel error -acodec copy -vcodec copy $outdir/$name.mp4
      if [[ `dursec` -gt `tmpdir=$outdir; dursec` ]]; then
        echo "$$ [error] packet loss $name.mp4"
        echo "$$ [warning] $name.mp4 d`ffmpeg -i $outdir/$name.mp4 2>&1 | grep -Po '(?<= D).+(?=\.[0-9]{2},)'`"
      fi
    else
      # archive
      for mulprog in `seq 0 $((${#mp4[@]} - 1))`
      do
        [ ! ${outdir[$mulprog]} ] && outdir[$mulprog]=$outdir_def
        echo "$$ ${mp4[$mulprog]} -> ${outdir[$mulprog]}/${name[$mulprog]}.mp4"
        optarg_f=`youtube-dl ${mp4[$mulprog]} --list-formats | awk '/(best)/{print $1}'`
        youtube-dl -q -f $optarg_f ${mp4[$mulprog]} -o ${outdir[$mulprog]}/${name[$mulprog]}.mp4
        if [ $option_i ]; then
          progsrc=`curl -s ${mp4[$mulprog]}`
          echo "$progsrc" | grep -Po '(?<="videoDetails":{).+?(?=","isCrawlable":)' | perl -pe 's/\\n/\n/g; s/,("[a-zA-Z0-9]+?":)/\n$1/g; s/("|(title|shortDescription)":|isOwnerViewing":.*)//g' | xmler | ${nkf/ --euc} | sed -E '/(Id|ds):/{H; d;}; $G' >${outdir[$mulprog]}/${name[$mulprog]}.txt
        fi
      done
    fi
  echo "$$ [$recdl] `date '+%m-%d %H:%M:%S'` $stopsuccess"
  ;;
esac

