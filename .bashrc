function PSWD() {
  local p="$*" space A B cols="${COLUMNS:-`tput cols 2>/dev/null || echo 80`}"
  p="${p/$HOME/\~}"         # shrink home down to a tilde
  if [ -n "$CYGWIN_OS" ] && [ "${p#/cygdrive/?/}" != "$p" ]; then
    p="${p:10:1}:${p:11}"   # /cygdrive/c/hi -> c:/hi
  fi
  space="$((${#USER}+${#HOSTNAME}+6))"  # width w/out the path
  if [ "$cols" -lt 60 ]; then echo -n "$N "; space=-29; p="$p$N\b"; fi
  if [ "$cols" -lt "$((space+${#p}+20))" ]; then # < 20 chars for the command
    A=$(( (cols-20-space)/4 ))      # a quarter of the space (-20 for cmd)
    if [ $A -lt 4 ]; then A=4; fi   # 4+ chars from beginning
    B=$(( cols-20-space-A*2 ))      # half (plus rounding) of the space
    if [ $B -lt 8 ]; then B=8; fi   # 8+ chars from end
    p="${p:0:$A}..${p: -$B}"
  fi
  echo "$p"
}
# Sample .bashrc for SuSE Linux
# Copyright (c) SuSE GmbH Nuernberg

# There are 3 different types of shells in bash: the login shell, normal shell
# and interactive shell. Login shells read ~/.profile and interactive shells
# read ~/.bashrc; in our setup, /etc/profile sources ~/.bashrc - thus all
# settings made here will also take effect in a login shell.
#
# NOTE: It is recommended to make language settings in ~/.profile rather than
# here, since multilingual X sessions would not work properly if LANG is over-
# ridden in every subshell.

# Some applications read the EDITOR variable to determine your favourite text
# editor. So uncomment the line below and enter the editor of your choice :-)
#export EDITOR=/usr/bin/vim
#export EDITOR=/usr/bin/mcedit

# For some news readers it makes sense to specify the NEWSSERVER variable here
#export NEWSSERVER=your.news.server

# If you want to use a Palm device with Linux, uncomment the two lines below.
# For some (older) Palm Pilots, you might need to set a lower baud rate
# e.g. 57600 or 38400; lowest is 9600 (very slow!)
#
#export PILOTPORT=/dev/pilot
#export PILOTRATE=115200

test -s ~/.alias && . ~/.alias || true
if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi
PS1='${debian_chroot:+($debian_chroot)}\[\033[38;5;206m\]\u@\h\[\033[00m\]:\[\033[38;5;206m\]\w>\[\033[00m\]'
export LESS_TERMCAP_mb=$'\e[0;31m' # begin bold => rot
export LESS_TERMCAP_md=$'\e[1;34m' # begin blink -> blau
export LESS_TERMCAP_so=$'\e[01;44;37m' # begin reverse video
export LESS_TERMCAP_us=$'\e[01;36m' # begin underline => tuerkis
export LESS_TERMCAP_me=$'\e[0m' # reset bold/blink
export LESS_TERMCAP_se=$'\e[0m' # reset reverse video
export LESS_TERMCAP_ue=$'\e[0m' # reset underline
export GROFF_NO_SGR=1           # for konsole and gnome-terminal
# Shorten home dir, cygwin drives, paths that are too long
if [ -d /cygdrive ] && uname -a |grep -qi cygwin; then CYGWIN_OS=1; fi

PSC() { echo -ne "\[\033[${1:-0;38}m\]"; }
PR="0;31"       # default color used in prompt is green
if [ "$(id -u)" = 0 ]; then
    sudo=41     # root is red background
  elif [ "$USER" != "${SUDO_USER:-$USER}" ]; then
    sudo=31     # not root, not self: red text
  else sudo="$PR"   # standard user color
fi
PROMPT_COMMAND='[ $? = 0 ] && PS1=${PS1[1]} || PS1=${PS1[2]}'
PSbase="$(PSC $sudo)\u$(PSC $PR)@\h $(PSC 33)\$(PSWD \w)"
PS1[1]="$PSbase$(PSC $PR)>$(PSC)"
PS1[2]="$PSbase$(PSC  31)>$(PSC)"
PS1="${PS1[1]}"
unset sudo PR PSbase
