#!/bin/bash

env_file=".env"
address=""
contract=""
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
        --address)
            if [[ -n "$2" ]]; then
                address=$2
            else
                echo "Error: Missing address after '--address'"
                exit 1
            fi
            shift
            ;;
        --contract)
            if [[ -n "$2" ]]; then
                contract=$2
            else
                echo "Error: Missing contract after '--contract'"
                exit 1
            fi
            shift
            ;;
        --verbosity)
            if [[ -n "$2" ]]; then
                verbosity=$2
            else
                echo "Error: Missing verbosity after '--verbosity'"
                exit 1
            fi
            shift
            ;;
        *)
            echo "Error: Unrecognized argument '$1'"
            exit 1
            ;;
    esac
    shift
done

if [[ ! -f $env_file ]]; then
    echo "Error: Environment file '$env_file' does not exist."
    exit 1
fi

if [[ -z "$address" ]]; then
    echo "Error: No address provided. Use '--address' to specify an address."
    exit 1
fi

if [[ -z "$contract" ]]; then
    echo "Error: No contract provided. Use '--contract' to specify a contract."
    exit 1
fi

source $env_file

forge fmt

forge verify-contract --rpc-url $RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY $address $contract
