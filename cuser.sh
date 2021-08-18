#!/bin/sh

# cuser - cluster monitoring tool
# by Kyerim Che

IN_FILE_NODES=/home/software/ctop/bin/.ctop/nodes

while read line
do
    [ "$line" == "" ] && continue
    [[ $line == \#* ]] && continue
    [[ $line == medicine-master* ]] && continue

    [ -z "${i}" ] && i=0

    col=($line)
    name[${i}]=${col[0]}
    ip[${i}]=${col[1]}

    n=$(( ${#col[@]}-2 ))

    for j in `seq 2 $[ $n + 1 ]`; 
    do
        if [[ ${col[$j]} == np\=* ]]; then
            np[$i]=${col[$j]:3}
        elif [[ ${col[$j]} == c\=* ]]; then
            c[$i]=$(( ${col[$j]:2} + 2 ))
        elif [[ ${col[$j]} == r\=* ]]; then
            r[$i]=$(( ${col[$j]:2} + 3 ))
        elif [[ ${col[$j]} == size\=* ]]; then
            size[${i}]=${col[$j]:5}
        fi
    done

    d[${i}]=$(( ${c[${i}]} + ${size[${i}]} - 1 ))

    (( i++ ))

done < $IN_FILE_NODES

get_usage() {
    own=$(id -nu)
    cpus=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
    total_mem=$(free | awk '/Mem:/ { print $2 }')

    echo "USER  CPU usage(%)    MeM usage(%)"
    # echo "USER  CPU usage(%)"
    for USER in `getent passwd | getent passwd | awk -F ":" '1001<$3' | awk -F ":" '$3<10000 {print $1}' | sort -u`
    do
        # print other USER's CPU usage in parallel but skip own one because
        # spawning many processes will increase our CPU usage significantly
        if [ "$USER" = "$own" ]; then continue; fi
        (top -b -n 1 -u "$USER" | awk -v USER=$USER -v CPUS=$cpus -v MEMS=$total_mem 'BEGIN {cpu_sum = 0.0; mem_sum += 0.0}
        NR>7 { cpu_sum += $9; mem_sum += $10;}
        END { if (cpu_sum > 0.0 || mem_sum > 0.0) printf"%s \t %.2f \t %.2f \n",USER,cpu_sum/CPUS,mem_sum;}') &
       
        # don't spawn too many processes in parallel
        sleep 0.05
    done
    wait

    # print own CPU usage after all spawned processes completed
    (top -b -n 1 -u "$own" | awk -v USER=$own -v CPUS=$cpus -v MEMS=$total_mem 'BEGIN {cpu_sum = 0.0; mem_sum += 0.0}
    NR>7 { cpu_sum += $9; mem_sum += $10;}
    END { if (cpu_sum > 0.0 || mem_sum > 0.0) printf"%s \t %.2f \t %.2f \n",USER,cpu_sum/CPUS,mem_sum;}')
}

dash_line='---------------------------';
for i in `seq 0 $(( ${#name[@]} - 1 ))`; 
do
    echo "${dash_line} ${name[$i]} (IP Address: `echo ${ip[$i]}` )${dash_line}";
    # ssh ${ip[$i]} 'w | grep -v "w$" | cut -f1 -d " " | grep -v USER | grep -v -e "^$"'
    ssh ${ip[$i]} "$(typeset -f get_usage); get_usage"
    
    #pid[${i}]=$!
done

#kill -9 ${pid[@]}
