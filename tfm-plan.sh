set -e 
working_folder=$(pwd)

log_action() {
    echo "${1^^} ..."
}

log_error() {
    local RED='\033[0;31m'
    local NC='\033[0m' # No Color
    echo -e "\n${RED}${1^^} ${NC}..."
}
export -f log_error


log_key_value_pair() {
    echo "    $1: $2"
}

set_up_aws_user_credentials() {
    unset AWS_SESSION_TOKEN
    export AWS_DEFAULT_REGION=$1
    export AWS_ACCESS_KEY_ID=$2
    export AWS_SECRET_ACCESS_KEY=$3
}

terraform_init() {
    session_name_key="<IAM_ROLE_SESSION_NAME>"
    backend_config_file=$1
    session_name_value=$2

    sed -i "s/$session_name_key/$session_name_value/" $backend_config_file
    terraform init -backend-config="$backend_config_file"
    sed -i "s/$session_name_value/$session_name_key/" $backend_config_file
}

log_action "planning terraform"

while getopts r:a:s:t:b:v:p:d:n: flag
do
    case "${flag}" in
       r) region=${OPTARG};;
       a) access_key=${OPTARG};;
       s) secret_key=${OPTARG};;
       t) tfm_folder=${OPTARG};;
       b) backend_config_file=${OPTARG};;
       v) tfvars_file=${OPTARG};;
       p) tfplan_output=${OPTARG};;
       d) destroy_mode=${OPTARG};;
       n) session_name_value=${OPTARG};;
    esac
done
if [[ "${destroy_mode}" == '' ]]; then
  destroy_mode='false'
fi

log_key_value_pair "region" "$region"
log_key_value_pair "access-key" "$access_key"
log_key_value_pair "terraform-folder" "$tfm_folder"
log_key_value_pair "backend-config-file" "$backend_config_file"
log_key_value_pair "tfvars-file" "$tfvars_file"
log_key_value_pair "tfplan-output" "$tfplan_output"
log_key_value_pair "destroy-mode" "$destroy_mode"

set_up_aws_user_credentials "$region" "$access_key" "$secret_key"

backend_config_file="$working_folder/$backend_config_file"
tfvars_file="$working_folder/$tfvars_file"
tfplan_output="$working_folder/$tfplan_output"
mkdir -p $(dirname $tfplan_output)

folder="$working_folder/$tfm_folder"
cd $folder
    terraform_init $backend_config_file $session_name_value
    set +e  # disable stop running if exit code different from 0
    if [ "$destroy_mode" = "true" ]; then 
        terraform plan -destroy -var-file="$tfvars_file" -out="$tfplan_output" -detailed-exitcode
    else
        terraform plan -var-file="$tfvars_file" -out="$tfplan_output" -detailed-exitcode
    fi
    tf_plan_exit_code=$?
    set -e  # enable stop running if exit code different from 0
cd "$working_folder"

case "$tf_plan_exit_code" in
    2)
        log_action "changes detected to be added to the job summary"
        TF_DETECT_CHANGES="true"
    ;;
    0)
        TF_DETECT_CHANGES="false"
    ;;
    *)
        log_error "error found performing tf plan"
        exit 1
    ;;

esac

log_key_value_pair "TF_DETECT_CHANGES" $TF_DETECT_CHANGES
echo "::set-output name=tf_detect_changes::$TF_DETECT_CHANGES"
