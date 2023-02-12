#!/bin/bash
# Used in HTB CTF Recon as a starting point for most challenges
set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ip> <port>" >&2
    exit 1
fi

export ip="$1"
export port="$2"
export url="http://$ip:$port"
echo $url

mkdir -p nmap
mkdir -p nikto
mkdir -p gobuster

# Get open ports
get_open_ports () {
  if ! ports=$(nmap -p- -Pn --min-rate=1000 -T4 $ip | grep '^[0-9]' | cut -d '/' -f 1 | tr '\n' ',' | sed s/,$//; echo $ports); then
    echo "Error: get_open_ports failed" >&2
    exit 1
  fi
}

# Probe open ports
probe_open_ports () {
  if ! sudo nmap -p$ports -Pn -sC -sV -O -oA nmap/nmap $ip; then
    echo "Error: probe_open_ports failed" >&2
    exit 1
  fi
}

# Web vuln scan
web_scan() {
  if ! nikto -h http://$ip/ -o nikto/nikto.txt; then
    echo "Error: web_scan failed" >&2
    exit 1
  fi
}

# Dir enumeration
dir_enum() {
  if ! gobuster dir -u http://$ip:$port -w /usr/share/wordlists/dirb/common.txt -o gobuster/gobuster; then
    echo "Error: dir_enum failed" >&2
    exit 1
  fi
}

# PW Brute Force with wfuzz + rockyou - change path as needed
wfuzz_pw_brute() {
  if ! wfuzz -Z -c -t 1 \
    -H "Content-Type: application/json" \
    -z file,/usr/share/wordlists/rockyou.txt \
    -d '{"username":"admin","password":"FUZZ"}' \
    -X POST -u "$ip:$port/api/login" -p localhost:8080; then
    echo "Error: wfuzz_pw_brute failed" >&2
    exit 1
  fi
}
