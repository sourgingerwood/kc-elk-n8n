# Requirements
- Docker (version 28.0.4)
- Docker Compose (version 1.29.2)
- python3
- nginx
# KEY hostnames
- app.ctt.tn
- kc.ctt.tn
- n8n.ctt.tn
- kibana.ctt.tn
# Configuration steps 
## Launch the Docker Compose file
     ~$ cd SOME_PATH/kc-elk && sudo ./start.sh
## Configure nginx 
     1. install nginx
     2. copy the certificate and key from SOME_PATH/kc-elk/nginx/self-signed/ to /etc/nginx/self-signed/
     3. replace nginx.conf with the one under SOME_PATH/kc-elk/nginx/
## Configure host resolution
     - SERVER_IP_ADDRESS ctt.tn kc.ctt.tn app.ctt.tn n8n.ctt.tn kibana.ctt.tn
## Add keycloak integration to kibana (port 5601)
    username: elastic
    password: changeme
    1. Under Fleet > Agent policies > Fleet-Server-Policy > Add Integration
    
    2. Find & select keycloak

    3. Click "Add Keycloak"

    4. use path /opt/keycloak/log/kc.log

    5. Click "save and continue"
## Import the Dashboard and alerts
    1. import the dashboard and alerts under SOME_PATH/kc-elk/kibana/ into kibana
