# based on Dark Blood Rewind, a new beginning.

# _bindupdate is stolen from https://github.com/zsh-users/zsh-syntax-highlighting/
# Copyright (c) 2010-2011 zsh-syntax-highlighting contributors All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
# Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
# Neither the name of the zsh-syntax-highlighting contributors nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


zle-update() {
  BUF=`sed -e 's/^[[:space:]]*//' <<< "${BUFFER}"`
  if [[ ${BUF} == "sudo "* || ${BUF} == "su -c "* ]]; then
    if [[ $highlight != "green" ]]; then
      highlight="green"
      setprompt()
      zle && zle reset-prompt
    fi
  else
    oldcolor="$highlight"
    setpromptcolor
    if [[ $highlight != $oldcolor ]]; then
      setprompt()
      zle && zle reset-prompt
    fi
  fi
}

zle -N zle-update

function setpromptcolor {
  if [ $EUID -ne 0 ]; then
    highlight="red"
  else
    highlight="green"
  fi
}

setpromptcolor

# precmd is called just before the prompt is printed
function update_precmd() {
    setpromptcolor
}
add-zsh-hook precmd update_precmd

function setprompt {
zle && zle zle-update
PROMPT=$'%{$fg[$highlight]%}┌[%{$fg_bold[white]%}%n%{$reset_color%}%{$fg[$highlight]%}@%{$fg_bold[white]%}%m%{$reset_color%}%{$fg[$highlight]%}] [%{$fg_bold[white]%}/dev/%y%{$reset_color%}%{$fg[$highlight]%}] %{$(git_prompt_info)%}%(?,%{$fg[$highlight]%}[%{$fg_bold[white]%}%?%{$reset_color%}%{$fg[$highlight]%}] $fg[red]<3,%{$fg[$highlight]%}[%{$fg_bold[white]%}%?%{$reset_color%}%{$fg[$highlight]%}] $fg[red]</3)%{$fg[110]%}%{$reset_color%}
%{$fg[$highlight]%}└[%{$fg_bold[white]%}%~%{$reset_color%}%{$fg[$highlight]%}]>%{$reset_color%} '
PS2=$' %{$fg[$highlight]%}|>%{$reset_color%} '

RPROMPT=$'%T'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[$highlight]%}[%{$fg_bold[white]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}%{$fg[$highlight]%}] "
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[$highlight]%} %{$reset_color%}"
}

setprompt

zle && zle zle-update

schedprompt() {
  emulate -L zsh
  zmodload -i zsh/sched

  # Remove existing event, so that multiple calls to
  # "schedprompt" work OK.  (You could put one in precmd to push
  # the timer 30 seconds into the future, for example.)
  integer i=${"${(@)zsh_scheduled_events#*:*:}"[(I)schedprompt]}
  (( i )) && sched -$i

  # Test that zle is running before calling the widget (recommended
  # to avoid error messages).
  # Otherwise it updates on entry to zle, so there's no loss.
  zle && zle reset-prompt
  #zle && zle zle-update

  # This ensures we're not too far off the start of the minute
  sched +5 schedprompt
}

schedprompt

# Stolen from https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/zsh-syntax-highlighting.zsh
# Rebind all ZLE widgets to make them invoke zle-update.
# This is doing vodoo magic. Remove it if it breaks anything :P
_bindupdate()
{
  # Load ZSH module zsh/zleparameter, needed to override user defined widgets.
  zmodload zsh/zleparameter 2>/dev/null || {
    echo 'zsh-syntax-highlighting: failed loading zsh/zleparameter.' >&2
    return 1
  }

  # Override ZLE widgets to make them invoke zle-update.
  local cur_widget
  for cur_widget in ${${(f)"$(builtin zle -la)"}:#(.*|_*|orig-*|run-help|which-command|beep)}; do
    case $widgets[$cur_widget] in

      # Already rebound event: do nothing.
      user:$cur_widget|user:_zsh_highlight_widget_*);;

      # User defined widget: override and rebind old one with prefix "orig-".
      user:*) eval "zle -N orig-$cur_widget ${widgets[$cur_widget]#*:}; \
                    _zsh_highlight_widget_$cur_widget() { builtin zle orig-$cur_widget \"\$@\" && zle-update }; \
                    zle -N $cur_widget _zsh_highlight_widget_$cur_widget";;

      ## Completion widget: override and rebind old one with prefix "orig-".
      completion:*) eval "zle -C orig-$cur_widget ${${widgets[$cur_widget]#*:}/:/ }; \
                          _zsh_highlight_widget_$cur_widget() { builtin zle orig-$cur_widget \"\$@\" && zle-update }; \
                          zle -N $cur_widget _zsh_highlight_widget_$cur_widget";;

      # Builtin widget: override and make it call the builtin ".widget".
      builtin) eval "_zsh_highlight_widget_$cur_widget() { builtin zle .$cur_widget \"\$@\" && zle-update }; \
                     zle -N $cur_widget _zsh_highlight_widget_$cur_widget";;

      # Default: unhandled case.
      *) echo "zsh-syntax-highlighting: unhandled ZLE widget '$cur_widget'" >&2 ;;
    esac
  done
}

_bindupdate
