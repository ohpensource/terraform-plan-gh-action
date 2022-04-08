set -e 
working_folder=$(pwd)

log_action() {
    echo "${1^^} ..."
}

log_key_value_pair() {
    echo "    $1: $2"
}

set_up_aws_user_credentials() {
    unset AWS_SESSION_TOKEN
    export AWS_DEFAULT_REGION=$1
    export AWS_ACCESS_KEY_ID=$2
    export AWS_SECRET_ACCESS_KEY=$3
}

log_action "planning terraform"

while getopts r:a:s:t:b:v:p:d: flag
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
    terraform init -backend-config="$backend_config_file"
    if [ "$destroy_mode" = "true" ]; then 
        terraform plan -destroy -var-file="$tfvars_file" -out="$tfplan_output"
    else
        terraform plan -var-file="$tfvars_file" -out="$tfplan_output"
    fi
cd "$working_folder"