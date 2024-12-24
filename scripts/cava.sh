#! /bin/bash

pipe="/tmp/cava.fifo"
if [ -p $pipe ]; then
    unlink $pipe
fi
mkfifo $pipe

# write cava config
config_file="/tmp/polybar_cava_config"
echo "
[general]
bars = 30
sensitivity = 80
[output]
method = raw
raw_target = $pipe
data_format = ascii
ascii_max_range = 7
" > $config_file

# run cava in the background
cava -p $config_file &
cava_pid=$!
trap "kill $cava_pid" EXIT
# reading data from fifo
while read -r cmd; do
    echo $cmd 
done < $pipe
# pkill -9 cava
