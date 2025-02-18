#!/bin/bash

env_file=".env"

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

source $env_file

forge fmt

PRIVATE_KEY=$PRIVATE_KEY \
XCASH=$XCASH \
forge script script/Deploy-Bridge.s.sol --rpc-url $RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY --broadcast --verify
