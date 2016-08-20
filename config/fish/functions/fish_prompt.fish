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

  function git_is_repo -d "Check if directory is a repository"
    test -d .git; or command git rev-parse --git-dir >/dev/null ^/dev/null
  end

  function git_is_dirty -d "Check if there are changes to tracked files"
    git_is_repo; and not command git diff --no-ext-diff --quiet --exit-code
  end

  function git_branch_name -d "Get the name of the current Git branch, tag or sha1"
      set -l branch_name (command git symbolic-ref --short HEAD ^/dev/null)

      if test -z "$branch_name"
          set -l tag_name (command git describe --tags --exact-match HEAD ^ /dev/null)

          if test -z "$tag_name"
              command git rev-parse --short HEAD ^ /dev/null
          else
              printf "%s\n" "$tag_name"
          end
      else
          printf "%s\n" "$branch_name"
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

  echo
  echo -s (set_color normal) $USER " at " (host_name) " in " (current_dir) (git_info) (last_exit_status) (rbenv_info)
  echo "> "
end
