#!/bin/bash
########################################################################
#Script Name	: CRYPTOCA
#Description	: Create a CA to sign and issue certificates.
#Args           : Interactive
#Author       	: Dari Garcia (manofftoday)
#GitHub         : https://github.com/manofftoday
#File           : cryptoca.sh
#Description    : Execution workflow
########################################################################
# Source Functions
# This section imports the functions required to work
# ca - CA generation related functions
# common - common workflow functions
# config_gen - OpenSSL config file generator
# csr - certificate signing requests functions
# private - private key functions
#################################
source ca
source common
source config_gen
source csr
source private
#################################
# Modify the cryptoca.conf file to your needs.
##################################
source cryptoca.conf
#############################
#Execution workflow
#############################
main_menu;