#!/usr/bin/env bash

tmpdir=/tmp
vartmpdir=/var/tmp
outdir=$HOME/Downloads; outdir_def=$outdir
nkf='nkf --fb-skip -m0 -Z1 -Lu'
xmler() {
  sed -E "s/&amp;nbsp;/ /g; s/&(apos|#039);/'/g; s/&(quot|#034);/\"/g; s/&(amp|#038);/\&/g; s/&lt;/</g; s/&gt;/>/g"
}
omch=shadowverse-channel
ver=1.2.1

usage() {
  echo "nico-dl-cron.sh($ver): cron utility for youtube-dl"
  echo '  <ch> (-i) (--filter=wd|FILE) (-o outname)    download'
  echo '                                                filter=FILE:from file'
  echo "                                                omittedch:$omch"
  echo '  -U <ch>                                      cache update'
  echo '  --ignore-U (nr) <ch> (-i) (--filter=) (-o )  ignore updates download'
  echo '                                                nr:to go back'
  echo '  -n <ch>                                      updates'
  echo "                                                omitted:${omch}"
  echo '  -N <ch>                                      newer'
  echo '  -h                                           help'
  exit 0
}

url=https://ch.nicovideo.jp
videosort='video?sort=f&order=d'

cherr() {
  echo "$$ [error] not found channel=$ch"
  echo "$$ [warning] using default($omch)"
  ch=$omch
}

mkcache() {
  [ ! -f $vartmpdir/nico_${ch}_cache ] && touch $vartmpdir/nico_${ch}_cache
}

case $1 in
  `[ ! $1 ]`|-h)
  usage
  ;;
  -n*|-N*)
  [ ! ${1:2} ] && ch=$2 || ch=${1:2}
  [ ! $ch ] && cherr
  chsrc=`curl -s $url/$ch/$videosort`
  mkcache
  if [ "$1" = '-N' ]; then
    if [ -s $vartmpdir/nico_${ch}_cache ]; then
      newernet=`echo "$chsrc" | sed -n -E '/^[ ]*[0-9]{4}/s/^[ ]*//p' | head -1`
      newercache=`tail -1 $vartmpdir/nico_${ch}_cache`
      [ "$newernet" != "$newercache" ] && sedp=`echo "$chsrc" | sed -n "/\`tail -1 $vartmpdir/nico_${ch}_cache\`/="` || exit 0
    else
      sedp='$'
    fi
  else
    sedp='$'
  fi
  echo "$chsrc" | sed -n 1,${sedp}p 2>/dev/null | sed -n -E "/^[ ]*(>|<var title=')/s/(^[ ]*(>|<var title=')|<\/a>|')//gp" | grep -v -E '([<;]|^$)' | tr '>' '\n' | sed '$d' | tac | $nkf
  ;;
  *)
  name=(`echo $* | grep -Po '(?<= -o).+?(?=( --filter|$))' | tr ' ' '\n' | tac`)
  [[ `echo $* | grep '\-i'` ]] && option_i=on
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
        optarg_iU=$2
        ch=$3
        ;;
        *)
        optarg_iU=1
        ch=`echo $* | grep -Po '(?<= ).+?(?=( |$))'`
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
  [[ ! $ch || $ch == '-i' ]] && cherr
  chsrc=`curl -s $url/$ch/$videosort`
  # make cache
  chid=(`echo "$chsrc" | grep -Po '(?<=watch/)[0-9]*' | uniq | sort -r`)
  mkcache
  if [[ `cat $vartmpdir/nico_${ch}_cache | sed '$d'` != `echo ${chid[@]} | tr ' ' '\n'` || $option_U ]]; then
    updatech=($(diff <(cat $vartmpdir/nico_${ch}_cache 2>/dev/null | sed '$d') <(echo ${chid[@]} | tr ' ' '\n') | grep -Po '(?<=> ).+'))
    if [ $filter ]; then
      filtering() {
        [ "${#filterwd[@]}" -ge 2 ] && filterwd=`echo ${filterwd[@]} | $nkf | tr ' ' '|'`
        for flt in `seq 0 $((${#updatech[@]} - 1))`
        do
          updatech_flt=(${updatech_flt[@]} $(echo "$chsrc" | $nkf | grep "${updatech[$flt]}" | grep -E "($(echo $filterwd | $nkf))" | grep -Po '(?<=watch/)[0-9]*'))
        done
        if [ ! $optarg_iU ]; then
          updatech_flt=($(diff $vartmpdir/nico_${ch}_cache <(echo ${updatech_flt[@]} | tr ' ' '\n') | grep -Po '(?<=> ).+'))
        else
          updatech_flt=($(echo "$chsrc" | $nkf | grep -E "($(echo $filterwd | $nkf))" | grep -Po '(?<=watch/)[0-9]*' | uniq | head -$optarg_iU))
        fi
      }
      filterwd=`echo $* | grep -Po '(?<=--filter=).*?(?=( |$))'`
      case $filterwd in
        FILE|`[ ! $filterwd ]`)
        if [ -f $vartmpdir/nico_${ch}_filter ]; then
          filterwd=(`$nkf $vartmpdir/nico_${ch}_filter`)
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
    [[ `echo "$chsrc" | grep 'purchase_type'` ]] && premiere=(`echo "$chsrc" | grep 'purchase_type' | grep -Po '(?<=watch/)[0-9]*' | sort | uniq`)
    if [ "$premiere" ]; then
      [ "${#premiere[@]}" -ge 2 ] && premiere=`echo ${premiere[@]} | tr ' ' '|'`
      updatech=(`echo ${updatech[@]} | tr ' ' '\n' | grep -v -E "($premiere)"`)
      chid=(`echo ${chid[@]} | tr ' ' '\n' | grep -v -E "($premiere)"`)
    fi
    # cachefile update
    echo ${chid[@]} | tr ' ' '\n' >$vartmpdir/nico_${ch}_cache
    echo "$chsrc" | sed -n '/^[ ]*[0-9]/s/^[ ]*//gp' | head -1 >>$vartmpdir/nico_${ch}_cache
    # cache updates only
    [ "$option_U" = 'on' ] && exit 0
    # no update filtering out
    [[ $filter && ! $updatech ]] && echo "`date '+%Y-%m-%d %H:%M:%S'` nico-dl-cron.sh: no update $ch filter=$filterwd" | $nkf && exit 0
    # no update premiere out
    [[ $premiere && ! $updatech ]] && echo "`date '+%Y-%m-%d %H:%M:%S'` nico-dl-cron.sh: no update $ch" && exit 0
    # ignore-U
    if [ "$option_U" = 'off' ]; then
      if [ ! $filter ]; then
        updatech=(`head -$optarg_iU $vartmpdir/nico_${ch}_cache`)
      else
        updatech=(`echo ${updatech_flt[@]} | tr ' ' '\n' | head -${optarg_iU}`)
      fi
    fi
    # naming
    if [ "$option_U" != 'on' ]; then
      for upchid in `seq 0 $((${#updatech[@]} - 1))`
      do
        mp4[$upchid]=${url/ch/www}/watch/${updatech[$upchid]}
        date=`curl -s ${mp4[$upchid]} | grep -Po '(?<=release_date" content=").+(?=T)' | tr -d '-'`
        [[ ! $date ]] && date=`date +%Y%m%d`
        # separate dir name
        if [[ ${name[$upchid]} ]]; then
          if [[ `echo ${name[$upchid]} | grep '/'` ]]; then
            outdir[$upchid]=${name[$upchid]%/*}
            [ ! -e ${outdir[$upchid]} ] && mkdir -p ${outdir[$upchid]}
          fi
          if [ ${name[$upchid]: -1} != '/' ]; then
            name[$upchid]=${name[$upchid]##*/}$date'_'${updatech[$upchid]}
          else
            name[$upchid]=$ch'_'$date'_'${updatech[$upchid]}
          fi
        else
          name[$upchid]=$ch'_'$date'_'${updatech[$upchid]}
        fi
      done
    fi
    # download
    [[ ! ${mp4[@]} ]] && echo 'NULL mp4[@], exit' && exit 1
    echo "$$ $0 $*"
    echo "$$ [download] `date '+%m-%d %H:%M:%S'` start"
    for mulprog in `seq 0 $((${#mp4[@]} - 1))`
    do
      [ ! ${outdir[$mulprog]} ] && outdir[$mulprog]=$outdir_def
      echo "$$ youtube-dl ${mp4[$mulprog]} -> ${outdir[$mulprog]}/${name[$mulprog]}.mp4"
      youtube-dl -q ${mp4[$mulprog]} -o ${outdir[$mulprog]}/${name[$mulprog]}.mp4 2>/dev/null
      # resume download
      until [ ! -f ${outdir[$mulprog]}/${name[$mulprog]}.mp4.part ]
      do
        youtube-dl -q ${mp4[$mulprog]} -o ${outdir[$mulprog]}/${name[$mulprog]}.mp4
        sleep 1
      done 2>/dev/null
      if [ $option_i ]; then
        progsrc=`curl -s ${mp4[$mulprog]}`
        echo "$progsrc" | grep -Po '(?<="uploadDate" content=").+(?=\+0900)' | tr 'T' ' ' >${outdir[$mulprog]}/${name[$mulprog]}.txt
        (echo; echo "$progsrc" | grep -E 'itemprop="(name|description)' | xmler | perl -pe 's/<br>/\n/g; s/_blank//g; s/<a href="//g; s/.*content="//; s/["<][^">]*[">]//g') >>${outdir[$mulprog]}/${name[$mulprog]}.txt
        (echo; echo "$progsrc" | grep -Po '(?<="url" content=").+(?=")') >>${outdir[$mulprog]}/${name[$mulprog]}.txt
        echo "$progsrc" | grep -Po '(?<="keywords" content=").+(?=">)' | tr ',' '\n' >>${outdir[$mulprog]}/${name[$mulprog]}.txt
      fi
    done
    echo "$$ [download] `date '+%m-%d %H:%M:%S'` successful"
  else
    echo "`date +'%m-%d %H:%M:%S'` nico-dl-cron.sh: no update $ch"
  fi
  ;;
esac

