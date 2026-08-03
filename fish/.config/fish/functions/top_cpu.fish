function top_cpu --description "Show top CPU-consuming processes"
    ps -eo pid:8,user:10,comm:30,%cpu:6 --sort=-%cpu |
        column -t |
        head -10
end
