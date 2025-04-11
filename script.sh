#!/bin/bash

env_file=
script_file=
extra_args=()

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --env-file)
            if [[ -n "$2" ]]; then
                env_file="$2"
            else
                echo "Error: Missing env file after '--env-file'"
                exit 1
            fi
            shift
            ;;
        --script-file)
            if [[ -n "$2" ]]; then
                script_file="$2"
            else
                echo "Error: Missing script file after '--script-file'"
                exit 1
            fi
            shift
            ;;
        *)
            extra_args+=("$1")
            ;;
    esac
    shift
done

if [[ -z "$env_file" ]]; then
    echo "Error: Please provide env file using '--env-file'."
    exit 1
fi

if [[ ! -f "$env_file" ]]; then
    echo "Error: Env file '$env_file' does not exist."
    exit 1
fi

if [[ -z "$script_file" ]]; then
    echo "Error: Please provide script file using '--script-file'."
    exit 1
fi

if [[ ! -f "$script_file" ]]; then
    echo "Error: Script file '$script_file' does not exist."
    exit 1
fi

forge fmt

source "$env_file"

forge script "$script_file" --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY" --etherscan-api-key "$ETHERSCAN_API_KEY" --broadcast --verify "${extra_args[@]}"