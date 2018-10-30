cat synth_list.txt | sed 's/;/\"\r\n`include \"/g' | sed '1s/^/`include \"/' | sed '$s/$/\"/' >> all.sv
