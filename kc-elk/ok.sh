#!/bin/bash

# Start the Pinggy tunnel with Web Debugger enabled
ssh -p 443 -R0:localhost:8000 -L4300:localhost:4300 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -T a.pinggy.io > /dev/null 2>&1 &
SSH_PID=$!

# Wait for the Web Debugger to be available
until curl -s http://localhost:4300/urls > /dev/null; do
  sleep 1
done

# Extract and print only the IP from the public URL
NEW_DOMAIN=$(curl -s http://localhost:4300/urls | jq -r '.urls[]' | grep '^https://')
echo $NEW_DOMAIN
#Optional: wait for the SSH process if you want the tunnel to persist
#wait $SSH_PID
