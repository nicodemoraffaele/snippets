#!/bin/bash
while [ true ]; do
 sleep 1
 TX_IN_MEMPOOL=`bitcoin-cli getmempoolinfo | jq .size`
 if [[ TX_IN_MEMPOOL -gt 0 ]]
 then
  echo "There are tx in mempool"
  bitcoin-cli generate 1
 else
  echo "There are NO tx in mempool"
 fi
done

