# tmux configuration for this project
source-file ~/.tmux.conf
new-session -s blog -n editor -d
send-keys -t blog 'cd ~/workspace/magic003.github.io' C-m
split-window -h -t blog
resize-pane -t blog:1.1
send-keys -t blog:1.2 'cd ~/workspace/magic003.github.io' C-m
select-pane -t blog:1.1
new-window -n console -t blog
send-keys -t blog:2 'cd ~/workspace/magic003.github.io && jekyll serve -w' C-m
select-window -t blog:1
