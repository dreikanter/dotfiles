function fish_prompt --description 'Write out the prompt'
  set --global last_status $status
  set -g prompt_sep " "

  function host_name
    echo (hostname|cut -d . -f 1)
  end

  function last_exit_status
    if test $last_status -ne 0
      echo -sn $prompt_sep (set_color yellow) "(exit " $last_status ")" (set_color normal)
    end
  end

  function rbenv_info
    if not [ -z (rbenv version-name) ]
      echo -sn $prompt_sep (set_color red) "(ruby " (rbenv version-name) ")" (set_color normal)
    end
  end

  function git_info
    if git_is_repo
      if git_is_dirty
        echo -sn (set_color yellow)
      else
        echo -sn (set_color green)
      end
      echo -sn $prompt_sep "(git " (git_branch_name) ")" (set_color normal)
    end
  end

  function current_dir
    echo -sn (set_color green) (prompt_pwd) (set_color normal)
  end

  echo -s (set_color normal) $USER "@" (host_name) " " (current_dir) (git_info) (last_exit_status) (rbenv_info) " > "
end
