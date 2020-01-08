#!/bin/bash

set -eu

umask 0077

CIPHER=$(mktemp)
aws s3 cp s3://secrets.binaris/ssh/binaris-dev-2019-10-22.pem.kms $CIPHER

aws --region us-east-1 kms decrypt --ciphertext-blob fileb://<(cat $CIPHER | base64 --decode) --query Plaintext --output text | base64 --decode  >~/.ssh/binaris-dev.pem

unlink $CIPHER

ssh-keygen -y -f ~/.ssh/binaris-dev.pem > ~/.ssh/binaris-dev.pem.pub
