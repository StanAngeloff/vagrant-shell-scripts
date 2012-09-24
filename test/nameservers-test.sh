#!/usr/bin/env bash

source "$( dirname "${BASH_SOURCE[0]}" )/../ubuntu.sh"

describe "Nameservers"

it_should_append_to_nameservers() {
  grep -v '8.8.8.8' '/etc/resolv.conf'
  nameservers-append '8.8.8.8'
  grep '8.8.8.8' '/etc/resolv.conf'
}

it_should_purge_local_nameservers() {
  echo "nameserver 10.0.255.1" | sudo tee -a '/etc/resolv.conf'
  echo "nameserver 10.0.255.2" | sudo tee -a '/etc/resolv.conf'
  grep '10.0.255.' '/etc/resolv.conf'
  nameservers-local-purge
  grep -v '10.0.255.' '/etc/resolv.conf'
}
