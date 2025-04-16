# Requirements
- Docker (version 28.0.4)
- Docker Compose (version 1.29.2)
- python3
# Configuration steps 
## Launch the Docker Compose configuration 
     ~$ cd /[path-to-project]/kc-elk
     ~$ docker-compose up
## Add keycloak integration to kibana (port 5601)
    username: elastic
    password: changeme
    
    1. Under Fleet > Agent policies > Fleet-Server-Policy > Add Integration
    
    2. * Find & select keycloak *

    3. Click "Add Keycloak"

    4. Set Paths to "/usr/share/elastic-agent/keycloak/log/kc.log"

    5. Click "save and continue"
## Configure realm, app & user for testing
    username: admin
    password: admin
    
    1. Create realm named "test-realm"

    2. Create client with client id "test-app" 
        - (set Web Origins to "http://localhost:5500/*")
        - (set Valid redirect URIs to "http://localhost:5500/*")

    4. Create a role for the test-app client

    3. Create a user

    5. Assign the test-app client role to user 
## start test-app
    $ cd /[path-to-project]/test-app/node-server
    $ node server.js

    or

    $ cd /[path-to-project]/test-app/vanilla-js
    $ python3 -m http.server 5500
    
    /!\ ATTENTION pour des raison liées au fait qui'in s'agit d'un environnement de développement veillez à utiliser le port 5500 ou alors il faudra modifier les ports dans server.js ou main.mjs
## Optionnal configuration
- import dashboard
    - Under Management > Saved Object
    - click Import and choose the file under "/[path-to-project]/kc-elk/kibana/kibana-dashboard.ndjson"
# Troubleshouting
(TODO)
