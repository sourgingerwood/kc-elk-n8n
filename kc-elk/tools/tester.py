# tester.py

import os
import sys
import subprocess
import re
from urllib.parse import urlencode

"""
Script de tests manuels (mode unique) pour Keycloak OIDC :
 1) LFI payloads
 2) Brute‑force credentials
 3) SQL injection sur username
 4) Bonnes credentials avec redirect critique

Sortie concise : code HTTP + message clé (ex. "Invalid parameter").
"""

# ─── Configuration ─────────────────────────────────────────────────────────
BASE_URL        = os.getenv('KEYCLOAK_URL',    'https://kc.ctt.tn:8443/')
REALM           = os.getenv('KEYCLOAK_REALM',  'test-realm')
CLIENT_ID       = os.getenv('KEYCLOAK_CLIENT_ID','test-app')
VERIFY_TLS      = os.getenv('VERIFY_TLS','False').lower() in ('true','1')
VALID_REDIRECT  = 'https://app.ctt.tn/callback'
CRITICAL_REDIRECT = 'https://app.ctt.tn/critical'

LFI_PAYLOADS    = ['/../../../etc/passwd', 'file:///etc/passwd', '../../../../../../etc/passwd']
BAD_CREDS       = [('wrong1','wrong'),('user','wrong'),('wrong','user'),('admin','admin'),('test','test')]
SQLI_PAYLOADS   = ["admin' OR '1'='1","' OR '1'='1' --","admin; DROP TABLE users;--","' UNION SELECT NULL--","' AND substring(password,1,1)='a' --"]

# ─── Utilitaire curl simplifié ─────────────────────────────────────────────
def run_curl_and_parse(cmd, error_pattern=None):
    # Exécute curl, capture sortie et code
    proc = subprocess.run(cmd, capture_output=True, text=True)
    raw = proc.stdout + proc.stderr
    # curl -w '%{http_code}' appends code at end of stdout
    http_code = raw[-3:]
    body = raw[:-3]
    # extraire message d'erreur si pattern fourni
    msg = None
    if error_pattern:
        m = re.search(error_pattern, body)
        if m:
            msg = m.group(1)
    # affichage concis
    print(f"→ HTTP {http_code}" + (f" | {msg}" if msg else ""))
    print('-'*40)

# ─── 1: LFI Tests ──────────────────────────────────────────────────────────
def test_lfi():
    print("\n=== LFI Redirect URI Tests ===")
    auth_path = f"/realms/{REALM}/protocol/openid-connect/auth"
    for uri in LFI_PAYLOADS:
        params = urlencode({'response_type':'code','client_id':CLIENT_ID,'redirect_uri':uri,'scope':'openid','state':'lfi'})
        url = f"{BASE_URL.rstrip('/')}{auth_path}?{params}"
        cmd = ['curl','-s','-k','-w','%{http_code}',url]
        print(f"Testing LFI: {uri}")
        # extraire <p class="instruction">…</p>
        run_curl_and_parse(cmd, r'<p class="instruction">([^<]+)')

# ─── 2: Bad Credential Tests ─────────────────────────────────────────────────
def test_bad_credentials():
    print("\n=== Bad Credential Tests ===")
    token_url = f"{BASE_URL.rstrip('/')}/realms/{REALM}/protocol/openid-connect/token"
    for user, pwd in BAD_CREDS:
        data = urlencode({'grant_type':'password','client_id':CLIENT_ID,'username':user,'password':pwd,'redirect_uri':VALID_REDIRECT})
        cmd = ['curl','-s','-k','-w','%{http_code}','-d',data,token_url]
        print(f"Testing creds: {user}/{pwd}")
        # message d'erreur JSON ou texte brut
        run_curl_and_parse(cmd, r'"error_description":"([^"]+)"')

# ─── 3: SQLi Tests ─────────────────────────────────────────────────────────
def test_sqli():
    print("\n=== SQLi Tests ===")
    token_url = f"{BASE_URL.rstrip('/')}/realms/{REALM}/protocol/openid-connect/token"
    for inj in SQLI_PAYLOADS:
        data = urlencode({'grant_type':'password','client_id':CLIENT_ID,'username':inj,'password':'user','redirect_uri':VALID_REDIRECT})
        cmd = ['curl','-s','-k','-w','%{http_code}','-d',data,token_url]
        print(f"Testing SQLi: {inj}")
        run_curl_and_parse(cmd, r'"error_description":"([^"]+)"')

# ─── 4: Good Creds + Critical Redirect ───────────────────────────────────────
def test_good_critical():
    print("\n=== Good Creds with Critical Redirect ===")
    token_url = f"{BASE_URL.rstrip('/')}/realms/{REALM}/protocol/openid-connect/token"
    user = os.getenv('KEYCLOAK_USER','user'); pwd = os.getenv('KEYCLOAK_PASS','user')
    data = urlencode({'grant_type':'password','client_id':CLIENT_ID,'username':user,'password':pwd,'redirect_uri':CRITICAL_REDIRECT})
    cmd = ['curl','-s','-k','-w','%{http_code}','-d',data,token_url]
    print(f"Testing good creds: {user}/{pwd} redirect_uri={CRITICAL_REDIRECT}")
    run_curl_and_parse(cmd, r'"access_token":"([^"]+)"')

# ─── Main ───────────────────────────────────────────────────────────────────
def main():
    test_lfi()
    test_bad_credentials()
    test_sqli()
    test_good_critical()

if __name__ == '__main__':
    main()

