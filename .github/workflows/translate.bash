#!/usr/bin/env bash
# Script: .github/workflows/translate.bash
# Author: Ricardo Malnati
# Creation Date: 2023-11-05
# Description: Treanslates the input file content.
# Dependencies: curl, jq, openssl

PREF_LANGUAGE="Brazilian Portuguese"
OPENAI_SYSTEM_CONTENT="You are a helpful system programmed to generate a translated version based on the markdown content inputed. Please provide the translation without any comments or suggestions, in the prefered language, ready to be applied to the repository."
OPENAI_USER_CONTENT="Based on the following input, identify the language and translate to ${PREF_LANGUAGE}. The answer should contain the translated content, only."

API_KEY="$1"
# Check for required files and variables
if [ -z "$API_KEY" ]; then
    echo "Error: Required variable API_KEY is not set in this bash file."
    echo "User Task: Update this bash file with the missing variables."
    exit 7
fi

INPUT_FILE="$2"
echo "Received to translate: $INPUT_FILE"
# Check for required files and variables
if [ -z "$INPUT_FILE" ]; then
    echo "Error: Required variable INPUT_FILE is not set in this bash file."
    echo "User Task: Update this bash file with the missing variables."
    exit 7
fi

# Check for files to translate 
FILE_NAME=$(basename "$INPUT_FILE")
if [[ "$FILE_NAME" =~ ^PTBR_ ]]; then
    echo "Warning: The FILE_NAME $FILE_NAME is not suitable for translation in this bash file."
    echo "User Task: Update only files written in English."
    exit 0
fi

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
    echo "Reason: Missing PREF_LANGUAGE, OPENAI_SYSTEM_CONTENT, or OPENAI_USER_CONTENT."
    echo "User Task: Update this bash file with the missing variables."
    exit 7
fi

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
# Check if the last command was successful
if [ $? -ne 0 ]; then
    echo "Error: API call to ChatGPT failed."
    echo "Reason: The curl command did not execute successfully."
    echo "Developer Fix: If you believe this is a bug, please contribute by opening an issue on the GitHub repository."
    echo "Support: If you have a support contract, please contact support with error code 8."
    echo "Community Help: For community assistance, post your issue on Stack Overflow with the tag 'translate.bash'."
    exit 8
fi

# Extract the commit message from the API response
TRANSLATED_CONTENT=$(echo "$API_RESPONSE" | jq -r '.choices[0].message.content' | sed -e 's/^.*a seguinte: //' -e 's/\\n/\n/g')

# Check if the last command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to parse API response."
    echo "Reason: The jq command did not execute successfully."
    echo "Developer Fix: If you believe this is a bug, please contribute by opening an issue on the GitHub repository."
    echo "Support: If you have a support contract, please contact support with error code 9."
    echo "Community Help: For community assistance, post your issue on Stack Overflow with the tag 'translate.bash'."
    exit 9
fi

BASE_DIR=$(dirname "$INPUT_FILE") 
TRANSLATED_FILE="$BASE_DIR/PTBR_$(basename "$INPUT_FILE")" 
TEXT_REFERENCE="Tradução para Português 🇧🇷"
REFERENCE="[$TEXT_REFERENCE]($TRANSLATED_FILE)"

# Check if the text reference already exists to avoid inserting the link again
if ! grep -q "$TEXT_REFERENCE" "$INPUT_FILE"; then
    # Reference doesn't exist, prepend at the first line of the original file
    awk -v ref="$REFERENCE" 'NR==1 && !/^'"$REFERENCE"'$/ {print ref} {print}' "$INPUT_FILE" > temp_file && mv temp_file "$INPUT_FILE"
fi


echo -e "$TRANSLATED_CONTENT" > "$TRANSLATED_FILE"
# Check if the last command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to write $TRANSLATED_FILE ."
    echo "Developer Fix: If you believe this is a bug, please contribute by opening an issue on the GitHub repository."
    echo "Support: If you have a support contract, please contact support with error code 9."
    echo "Community Help: For community assistance, post your issue on Stack Overflow with the tag 'translate.bash'."
    exit 9
fi

git add .
# Check if the last command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to 'git add . '."
    echo "Developer Fix: If you believe this is a bug, please contribute by opening an issue on the GitHub repository."
    echo "Support: If you have a support contract, please contact support with error code 9."
    echo "Community Help: For community assistance, post your issue on Stack Overflow with the tag 'translate.bash'."
    exit 9
fi

git commit -m "feat: auto translation 🇧🇷"
# Check if the last command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to commit $(dirname $INPUT_FILE)/PTBR_$(basename $INPUT_FILE)."
    echo "Developer Fix: If you believe this is a bug, please contribute by opening an issue on the GitHub repository."
    echo "Support: If you have a support contract, please contact support with error code 9."
    echo "Community Help: For community assistance, post your issue on Stack Overflow with the tag 'translate.bash'."
    exit 9
fi

git push

exit 0
