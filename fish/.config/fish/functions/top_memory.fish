function top_memory --description "Show top memory-consuming processes"
    ps -eo pid:8,user:10,comm:30,rss:12 --sort=-rss |
        awk 'NR>1 {$4=sprintf("%.1f MB",$4/1024)}1' |
        column -t |
        head -10
end
