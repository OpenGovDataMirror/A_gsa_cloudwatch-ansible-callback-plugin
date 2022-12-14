#!/bin/bash
# Script to request session token and set environment variables
# Assumes your credentials are set in a shared credentials file
# To use a different profile, set the AWS_PROFILE environment variable

# Unset the old token before requesting new token
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

PROFILE=$1

if [[ "x$PROFILE" == "x" ]]; then
	echo "Please provide a profile name as the first parameter"
	exit 1
fi

resp=$(aws iam list-mfa-devices --profile $PROFILE 2>&1)

if [[ $resp == *"User"*"is not authorized"* ]]; then
  device_sn=$(echo $resp | sed 's/^.*User: //' | sed 's/ is not authorized.*$//' | sed 's/user/mfa/')
else
  device_sn=$(echo $resp | jq '.MFADevices[0].SerialNumber' | sed 's/"//g')
 
fi

echo Device Serial Number: $device_sn

echo "Enter token code"

read token

resp=$(aws sts get-session-token --serial-number $device_sn --token-code $token --duration-seconds 129600 --profile $PROFILE)

echo $resp

AWS_2AUTH_PROFILE=default
export AWS_ACCESS_KEY_ID=$(echo $resp | jq '.Credentials.AccessKeyId' | sed 's/"//g')
echo Access Key: $AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$(echo $resp | jq '.Credentials.SecretAccessKey' | sed 's/"//g')
export AWS_SESSION_TOKEN=$(echo $resp | jq '.Credentials.SessionToken' | sed 's/"//g')
export AWS_SECURITY_TOKEN=$(echo $resp | jq '.Credentials.SessionToken' | sed 's/"//g')

`aws --profile $AWS_2AUTH_PROFILE configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"`
`aws --profile $AWS_2AUTH_PROFILE configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"`
`aws --profile $AWS_2AUTH_PROFILE configure set aws_session_token "$AWS_SESSION_TOKEN"`
