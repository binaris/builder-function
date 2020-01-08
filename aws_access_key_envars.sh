# Get the AWS access keys, either from .aws profile, or from ec2 role.
# These are temporary and not for production use (expiry is unpredictable)
if aws configure get aws_access_key_id >/dev/null; then
    export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
    export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
else
    role=$(aws sts get-caller-identity | jq -r '.Arn' | cut -d "/" -f 2)

    creds_endpoint="http://169.254.169.254/latest/meta-data/iam/security-credentials"

    export AWS_ACCESS_KEY_ID=$(curl -s $creds_endpoint/$role | jq -r '.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(curl -s $creds_endpoint/$role | jq -r '.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(curl -s $creds_endpoint/$role | jq -r '.Token')
    export AWS_SECURITY_TOKEN="$AWS_SESSION_TOKEN"
fi
