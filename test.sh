#!/bin/bash

env_file=
verbosity="-vv"
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
        --verbosity)
            if [[ -n "$2" ]]; then
                verbosity="$2"
            else
                echo "Error: Missing verbosity after '--verbosity'"
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

source "$env_file"

forge fmt

PRIVATE_KEY=$PRIVATE_KEY \
forge test --rpc-url "$RPC_URL" "$verbosity" "${extra_args[@]}"