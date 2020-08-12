#!/bin/bash
########################################################################
#Script Name	: CRYPTOCA
#Description	: Generate autosigned certificates in pem format to use to deploy OpenLDAP
#Args           :
#Author       	: Dari Garcia (manofftoday)
#GitHub         : https://github.com/manofftoday
########################################################################
#Variables
#################################
CA_NAME="GMV"
DIR_CA="/$CA_NAME"
COUNTRY="ES"
PROVINCE="MADRID"
LOCALITY="MADRID"
OUNAME="GMV"
UNITNAME="GALILEO"
EMAIL="admin@gmv.com"
#############################
#Functions
#############################
function main_menu(){
  clear
  A='Welcome to CRYPTOCA. Please enter your choice using the number keys: '
  echo $A
  options=("Create CA" \
  "Issue New Certificate" \
  "Quit")
  select opt in "${options[@]}"
  do
    case $opt in
            "Create CA")
                    clear
                    name_ca;
                    create_structure;
                    set_var;
                    config_file;
                    private_key_ca;
                    cert_CA;
                    verify_CA;
                    break
            ;;
            "Issue New Certificate")
                    clear
                    select_ca
                    private_cert;
                    csr_cert;
                    sign_csr_cert;
                    verify_cert;
                    break
            ;;
            "Quit")
                    break
            ;;
          *) echo "invalid option $REPLY";;
      esac
  done
}

function select_ca(){
  unset DIR_CA
  clear
  read -p "Enter the absolute CA Path: " DIR_CA
}

function name_ca(){
  unset a
  clear
  echo "Current CA name configured: $CA_NAME"
  echo "Would you like to choose a new CA name?[y/n]"
  read a
  if [ "$a" = "y" ]
  then
    clear
    unset DIR_CA
    unset CA_NAME
    read -p "Select the name for the CA:" CA_NAME
    echo "CA Selected: $CA_NAME"
    DIR_CA=/$CA_NAME
  fi
}

function create_structure(){
  unset a
  clear
  echo "Current CA Directory: $DIR_CA"
  echo "Would you like to create a new CA directory structure?[y/n]"
  read a
  if [ "$a" = "y" ]
  then
    echo "Creating new structure..."
    mkdir  $DIR_CA $DIR_CA/certs $DIR_CA/csr $DIR_CA/crl $DIR_CA/newcerts $DIR_CA/private
    chmod 700 $DIR_CA/private
    touch $DIR_CA/index.txt
    touch $DIR_CA/index.txt.attr
    echo "1000" > $DIR_CA/serial
  else
    clear
    read -p "Enter the absolute CA Path: " DIR_CA
  fi
}

function set_var(){
unset a
  clear
  cat << EOF
Current Variables:
countryName_default= $COUNTRY
stateOrProvinceName_default= $PROVINCE
localityName_default= $LOCALITY
organizationName_default=$OUNAME
organizationalUnitName_default=$UNITNAME
emailAddress_default=$EMAIL
EOF
  echo "Would you like to set the variables?[y/n]"
  read a
  if [ "$a" = "y" ]
  then
    read -p "Enter countryName: " COUNTRY
    read -p "Enter stateOrProvinceName: " PROVINCE
    read -p "Enter localityName: " LOCALITY
    read -p "Enter organizationName: " OUNAME
    read -p "Enter organizationalUnitName: " UNITNAME
    read -p "Enter emailAddress: " EMAIL
  fi
}

function config_file(){
  unset a
  clear
  echo "Would you like to set a new configuration file?[y/n]"
  read a
  if [ "$a" = "y" ]
  then
    cat << EOF > $DIR_CA/openssl.conf
[ ca ]
# man ca
default_ca = $CA_NAME

[ $CA_NAME ]
# Directory and file locations.
dir               = $DIR_CA/
certs             = $DIR_CA/certs
crl_dir           = $DIR_CA/crl
new_certs_dir     = $DIR_CA/newcerts
database          = $DIR_CA/index.txt
serial            = $DIR_CA/serial
RANDFILE          = $DIR_CA/private/.rand

# The root key and root certificate.
private_key       = $DIR_CA/private/$CA_NAME.key.pem
certificate       = $DIR_CA/certs/$CA_NAME.cert.pem

# For certificate revocation lists.
crlnumber         = $DIR_CA/crlnumber
crl               = $DIR_CA/crl/$CA_NAME.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of man ca.
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the ca man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the req tool (man req).
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256
# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca
# Extension for SANs
req_extensions      = v3_req

[ v3_req ]
# Extensions to add to a certificate request
# Before invoke openssl use: export SAN=DNS:value1,DNS:value2
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = otherName:1.3.6.1.4.1.311.20.2.3;UTF8:1999999999123456@$CA_NAME

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = $COUNTRY
stateOrProvinceName_default     = $PROVINCE
localityName_default            = $LOCALITY
0.organizationName_default      = $OUNAME
organizationalUnitName_default  = $UNITNAME
emailAddress_default            = $EMAIL

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates (man x509v3_config).
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
# Extensions for server certificates (man x509v3_config).
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ crl_ext ]
# Extension for CRLs (man x509v3_config).
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates (man ocsp).
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
    echo "Config file deployed"
  fi
}

function private_key_ca(){
  clear
  openssl genrsa -aes256 -out $DIR_CA/private/${CA_NAME}.key.pem 4096
  chmod 400 $DIR_CA/private/${CA_NAME}.key.pem
  echo "$CA_NAME private key created"
}

function cert_CA(){
  clear
  echo "Creating CA Certificate..."
  read -p "Enter the CA URL: " CAURL
  read -p "Valid Days: " DAYS
  export SAN=DNS:$CAURL
  openssl req -config $DIR_CA/openssl.conf \
    -key $DIR_CA/private/${CA_NAME}.key.pem \
    -new -x509 -days $DAYS -sha256 -extensions v3_ca \
    -out $DIR_CA/certs/${CA_NAME}.cert.pem
  chmod 444 $DIR_CA/certs/${CA_NAME}.cert.pem
  echo "CA certificate created"
}

function verify_CA(){
  clear
  echo "Verifying certificate..."
  openssl x509 -noout -text -in $DIR_CA/certs/${CA_NAME}.cert.pem
  echo "Verified."
}

function private_cert(){
  clear
  echo "Creating certificate issued by $CA_NAME"
  read -p "Enter the certificate URL: " SRVURL
  echo "Would you like to use aes256 to generate the certificate?[y/n]"
  read a
  if [ "$a" = "y" ]
  then
    openssl genrsa -aes256 -out $DIR_CA/private/${SRVURL}.key.pem 2048
  fi
  openssl genrsa -out $DIR_CA/private/${SRVURL}.key.pem 2048
  chmod 400 $DIR_CA/private/${SRVURL}.key.pem
}

function csr_cert(){
  clear
  echo "Creating certificate request... $SRVURL"
  openssl req -config $DIR_CA/openssl.conf \
      -key $DIR_CA/private/${SRVURL}.key.pem \
      -new -sha256 -out $DIR_CA/csr/${SRVURL}.csr.pem
  echo ".csr created for $SRVURL"
}

function sign_csr_cert(){
      clear
      echo "Signing certificate request... $SRVURL"
      openssl ca -config $DIR_CA/openssl.conf \
          -extensions v3_req -days 3650 -notext -md sha256 \
          -in $DIR_CA/csr/${SRVURL}.csr.pem \
          -out $DIR_CA/certs/${SRVURL}.cert.pem
      chmod 444 $DIR_CA/certs/${SRVURL}.cert.pem
}

function verify_cert(){
  clear
  echo "Verifying Certificate..."
  openssl x509 -noout -text -in ${DIR_CA}/certs/${SRVURL}.cert.pem
}

#############################
#Execution
#############################
main_menu;
