#!/bin/bash

env_file=".env"
match_path=""
verbosity=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --chain)
            if [[ -n "$2" ]]; then
                env_file="$2.env"
            else
                echo "Error: Missing chain after '--chain'"
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

if [[ ! -f $env_file ]]; then
    echo "Error: Environment file '$env_file' does not exist."
    exit 1
fi

source $env_file

forge fmt

forge test --rpc-url $RPC_URL $verbosity "${extra_args[@]}"