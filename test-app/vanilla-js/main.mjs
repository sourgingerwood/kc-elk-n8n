
import Keycloak from "https://cdn.jsdelivr.net/npm/keycloak-js@26.0.1/+esm";
document.addEventListener("DOMContentLoaded", function() {
    // Initialize Keycloak
    const keycloak = new Keycloak({
        url: 'https://localhost:8443',
        realm: 'test-realm',
        clientId: 'test-app'
    });

    const outputTextarea = document.getElementById('output');

    function logToTextarea(message) {
        const now = new Date();
        const timestamp = now.toLocaleString();
        outputTextarea.value += `[${timestamp}] ${message}\n`;
    }

    keycloak.init({ 
        enableLogging: true,
        // checkLoginIframe: false,
        flow: 'standard',
        onLoad: 'check-sso',
    }).then(function(authenticated) {
        console.log("make creader");
        logToTextarea(authenticated ? 'User is authenticated' : 'User is not authenticated');

        document.getElementById('loginBtn').addEventListener('click', function() {
            logToTextarea('Login button clicked');
            keycloak.login();
        });

        document.getElementById('logoutBtn').addEventListener('click', function() {
            logToTextarea('Logout button clicked');
            keycloak.logout();
        });

        document.getElementById('isLoggedInBtn').addEventListener('click', function() {
            const isLoggedInMessage = keycloak.authenticated ? 'User is logged in' : 'User is not logged in';
            logToTextarea('Is Logged In button clicked: ' + isLoggedInMessage);
            alert(isLoggedInMessage);
        });

        document.getElementById('accessTokenBtn').addEventListener('click', function() {
            if (keycloak.authenticated) {
                logToTextarea('Access Token button clicked: ' + keycloak.token);
                alert('Access Token: ' + keycloak.token);
            } else {
                const notLoggedInMessage = 'User is not logged in';
                logToTextarea('Access Token button clicked: ' + notLoggedInMessage);
                alert(notLoggedInMessage);
            }
        });

        document.getElementById('showParsedTokenBtn').addEventListener('click', function() {
            if (keycloak.authenticated) {
                const parsedToken = keycloak.tokenParsed;
                logToTextarea('Show Parsed Access Token button clicked: ' + JSON.stringify(parsedToken, null, 2));
                alert('Parsed Access Token: ' + JSON.stringify(parsedToken, null, 2));
            } else {
                const notLoggedInMessage = 'User is not logged in';
                logToTextarea('Show Parsed Access Token button clicked: ' + notLoggedInMessage);
                alert(notLoggedInMessage);
            }
        });

        document.getElementById('callApiBtn').addEventListener('click', function() {
            console.log("lele");
            logToTextarea('Call API button clicked');
            if (keycloak.authenticated) {
                fetch('https://4b215443be964e33bc1ef0373940400c.api.mockbin.io/', {
                    headers: {
                        'Authorization': 'Bearer ' + keycloak.token
                    }
                })
                .then(response => console.log("kere"))
                .then(data => {
                    logToTextarea('API call successful: ' + JSON.stringify(data));
                    console.log(data);
                })
                .catch(error => {
                    logToTextarea('API call failed: ' + error);
                    console.error('Error:', error);
                });
            } else {
                const notLoggedInMessage = 'User is not logged in';
                logToTextarea('API call failed: ' + notLoggedInMessage);
                alert(notLoggedInMessage);
            }
        });



    }).catch(function(error) {
        console.log(error);
        console.log('Failed to initialize');
    })
});