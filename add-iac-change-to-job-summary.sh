log_key_value_pair() {
    echo "    $1: $2"
}

file_path=$1

log_key_value_pair "file_path" $file_path

regex='Plan: ([0-9]+) to add, ([0-9]+) to change, ([0-9]+) to destroy'
summary="$(cat $file_path | grep 'Plan:')" # TF Summary starts with Plan:

if [[ "$summary" =~ $regex ]]
then
    resources_to_add="${BASH_REMATCH[1]}"
    resources_to_change="${BASH_REMATCH[2]}"
    resources_to_delete="${BASH_REMATCH[3]}"

    log_key_value_pair "resources_to_add" $resources_to_add
    log_key_value_pair "resources_to_change" $resources_to_change
    log_key_value_pair "resources_to_delete" $resources_to_delete

    echo "::set-output name=resources_to_add::${resources_to_add}"
    echo "::set-output name=resources_to_change::${resources_to_change}"
    echo "::set-output name=resources_to_delete::${resources_to_delete}"
    echo "$summary" >> $GITHUB_STEP_SUMMARY # output to Step Summary

else
    echo "$summary doesn't match" >&2 # this could get noisy if there are a lot of non-matching files
fi
