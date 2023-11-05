#!/usr/bin/env bash
# Script: .github/workflows/translate.bash
# Author: Ricardo Malnati
# Creation Date: 2023-11-05
# Description: Treanslates the input file content.
# Dependencies: curl, jq, openssl


PREF_LANGUAGE="Brazilian Portuguese"
OPENAI_SYSTEM_CONTENT="You are a helpful system programmed to generate a translated version based on the input. Please provide the translation without any comments or suggestions, in the prefered language."
OPENAI_USER_CONTENT="Based on the following input, identify the language and translate to ${PREF_LANGUAGE}."

# Check for curl
if ! command -v curl &> /dev/null; then
  echo "Error: curl is not installed. Reason: The script requires curl for making API calls."
  echo "Developer Fix: Install curl via Homebrew by running 'brew install curl'."
  exit 3
fi

# Check for jq
if ! command -v jq &> /dev/null; then
  echo "Error: jq is not installed. Reason: The script requires jq for JSON parsing."
  echo "Developer Fix: Install jq via Homebrew by running 'brew install jq'."
  exit 4
fi

# Check for required files and variables
if [ -z "$PREF_LANGUAGE" ] || [ -z "$OPENAI_SYSTEM_CONTENT" ] || [ -z "$OPENAI_USER_CONTENT" ]; then
    echo "Error: Required variables not set in this bash file."
    echo "Reason: Missing PASSPHRASE, PREF_LANGUAGE, OPENAI_SYSTEM_CONTENT, or OPENAI_USER_CONTENT."
    echo "User Task: Update this bash file with the missing variables."
    exit 7
fi

# Decrypt API Key
API_KEY="$1"

INPUT_FILE="$2"
echo "Received: $INPUT_FILE"

INPUT_CONTENT=$(cat "$INPUT_FILE")

# Prepare the JSON payload using jq
JSON_PAYLOAD=$(jq -n \
                  --arg model "gpt-3.5-turbo-16k" \
                  --arg sys_content "$OPENAI_SYSTEM_CONTENT The user speaks $PREF_LANGUAGE." \
                  --arg user_content "$OPENAI_USER_CONTENT: $INPUT_CONTENT" \
                  '{model: $model, messages: [{role: "system", content: $sys_content}, {role: "user", content: $user_content}]}')

# Make an API call to ChatGPT for analysis
API_RESPONSE=$(curl -s -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    "https://api.openai.com/v1/chat/completions")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: API call to ChatGPT failed."
    echo "Reason: The curl command did not execute successfully."
    echo "Developer Fix: If you believe this is a bug, please contribute by opening an issue on the GitHub repository."
    echo "Support: If you have a support contract, please contact support with error code 8."
    echo "Community Help: For community assistance, post your issue on Stack Overflow with the tag 'auto-commit-msg'."
    exit 8
fi

# Extract the commit message from the API response
TRANSLATED_CONTENT=$(echo "$API_RESPONSE" | jq -r '.choices[0].message.content')

# Check if jq command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to parse API response."
    echo "Reason: The jq command did not execute successfully."
    echo "Developer Fix: If you believe this is a bug, please contribute by opening an issue on the GitHub repository."
    echo "Support: If you have a support contract, please contact support with error code 9."
    echo "Community Help: For community assistance, post your issue on Stack Overflow with the tag 'auto-commit-msg'."
    exit 9
fi

echo $TRANSLATED_CONTENT > "PTBR_${INPUT_FILE}"

git config user.email "${{ github.actor }}@users.noreply.github.com"
git config user.name "${{ github.actor }}"

git add .
git commit -m "feat: Added PTBR_${INPUT_FILE}"
git push

exit 0
