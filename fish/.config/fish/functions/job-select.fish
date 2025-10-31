function job-select
    set -l job_list (jobs)

    if test -z "$job_list"
        echo "No background jobs"
        return
    end

    set -l selected (printf '%s\n' $job_list | sk --reverse --header="Select job to bring to foreground")

    if test -n "$selected"
        set -l group_id (echo $selected | awk '{print $2}')
        if test -n "$group_id"
            fg $group_id
        end
    end
end
