#!/bin/bash -e
aws s3 cp --recursive s3://vscode-dev/ssl/ /root/.config/code-server/ssl/
code-server