#!/usr/bin/env bash
[[ ! ${WARDEN_COMMAND} ]] && >&2 echo -e "\033[31mThis script is not intended to be run directly!" && exit 1

WARDEN_SSL_DIR=~/.warden/ssl

if ! [[ -d ${WARDEN_SSL_DIR}/rootca/ ]]; then
    mkdir -p ${WARDEN_SSL_DIR}/rootca/{certs,crl,newcerts,private}

    touch ${WARDEN_SSL_DIR}/rootca/index.txt
    echo 1000 > ${WARDEN_SSL_DIR}/rootca/serial
fi

# create CA root certificate if none present
if [[ ! -f "${WARDEN_SSL_DIR}/rootca/private/ca.key.pem" ]]; then
  echo "==> Generating private key for local root certificate"
  openssl genrsa -out "${WARDEN_SSL_DIR}/rootca/private/ca.key.pem" 2048
fi

if [[ ! -f "${WARDEN_SSL_DIR}/rootca/certs/ca.cert.pem" ]]; then
  echo "==> Signing root certificate (Warden Proxy Local CA)"
  openssl req -new -x509 -days 7300 -sha256 -extensions v3_ca \
    -config "${WARDEN_DIR}/etc/openssl/rootca.conf"           \
    -key "${WARDEN_SSL_DIR}/rootca/private/ca.key.pem"        \
    -out "${WARDEN_SSL_DIR}/rootca/certs/ca.cert.pem"         \
    -subj "/C=US/O=Warden Proxy Local CA"
fi

if ! security dump-trust-settings -d | grep 'Warden Proxy Local CA' >/dev/null; then
  echo "==> Trusting root certificate (requires sudo privileges)"
  sudo security add-trusted-cert -d -r trustRoot \
      -k /Library/Keychains/System.keychain "${WARDEN_SSL_DIR}/rootca/certs/ca.cert.pem"
fi
