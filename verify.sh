#!/bin/bash

env_file=
address=
contract=
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
        --address)
            if [[ -n "$2" ]]; then
                address="$2"
            else
                echo "Error: Missing address after '--address'"
                exit 1
            fi
            shift
            ;;
        --contract)
            if [[ -n "$2" ]]; then
                contract="$2"
            else
                echo "Error: Missing contract after '--contract'"
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

if [[ -z "$env_file" || ! -f "$env_file" ]]; then
    echo "Error: Missing env file."
    exit 1
fi

if [[ -z "$address" ]]; then
    echo "Error: Please provide address using '--address'."
    exit 1
fi

if [[ -z "$contract" ]]; then
    echo "Error: Please provide contract using '--contract'."
    exit 1
fi

source "$env_file"

forge fmt

forge verify-contract --rpc-url "$RPC_URL" --etherscan-api-key "$ETHERSCAN_API_KEY" "${extra_args[@]}" "$address" "$contract"