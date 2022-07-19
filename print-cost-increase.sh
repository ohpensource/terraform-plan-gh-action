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

while getopts r:a:s:t:b:p: flag
do
    case "${flag}" in
       r) region=${OPTARG};;
       a) access_key=${OPTARG};;
       s) secret_key=${OPTARG};;
       t) tfm_folder=${OPTARG};;
       b) backend_config_file=${OPTARG};;
       p) tfm_plan=${OPTARG};;
    esac
done

log_key_value_pair "terraform-folder" $tfm_folder
log_key_value_pair "backend-config-file" $backend_config_file
log_key_value_pair "terraform-plan-file" $tfm_plan

set_up_aws_user_credentials $region $access_key $secret_key

backend_config_file="$working_folder/$backend_config_file"
tfm_plan="$working_folder/$tfm_plan"

folder="$working_folder/$tfm_folder"
cd $folder

tf_show_output="tf_output.json"
terraform init -backend-config="$backend_config_file"
terraform show -json $tfm_plan > $tf_show_output

echo "######## costs ########"
# Downloads the CLI based on your OS/arch and puts it in /usr/local/bin
curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
infracost --version # Should show 0.10.7
echo "# Cost Increase:" >> $GITHUB_STEP_SUMMARY
infracost diff  --path "$tf_show_output" >> $GITHUB_STEP_SUMMARY

echo "##### addding comment to PR $PR_NUMBER"
infracost_output="infra_output.json"
infracost diff  --path "$tf_show_output"
infracost diff  --path "$tf_show_output" --out-file "$infracost_output"

echo "##### GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
infracost comment github --path "$infracost_output" --repo $GITHUB_REPOSITORY --github-token $GH_TOKEN --pull-request $PR_NUMBER --behavior=update

cd "$working_folder"
