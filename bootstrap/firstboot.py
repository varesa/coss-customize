#!/usr/bin/env python3

import ipaddress
import json
import os
import requests
from subprocess import check_output
import time


def start_devices():
    for line in check_output(['nmcli', '-t', '-f', 'NAME,ACTIVE', 'connection']).decode().strip().split('\n'):
        device, status = line.split(':')
        if device.startswith('eno') or device.startswith('enp'):
            if status != 'yes':
                try:
                    check_output(['nmcli', 'c', 'up', device])
                except Exception:
                    print("Error bringing up", device)


def get_addresses():
    interfaces = json.loads(check_output(['ip', '-j', 'addr']))

    for interface in interfaces:
        for address in interface['addr_info']:
            if address['family'] == 'inet' and address['prefixlen'] == 30:
                yield address['local']


def get_next_stage():
    while True:
        for address in get_addresses():
            peer_ip = str(ipaddress.IPv4Address(address) - 1)

            try:
                r = requests.get(f'http://{peer_ip}:50005/provision')
                if r.status_code == 200:
                    return r.text, peer_ip
            except Exception:
                pass

        print("Unable to find second stage")
        time.sleep(10)


start_devices()
script, peer_ip = get_next_stage()

S2_PATH = '/root/network_stage2'

with open(S2_PATH, 'w') as f:
    f.write(script)

os.chmod(S2_PATH, 0o700)
print(check_output([S2_PATH, peer_ip]).decode())

os.remove('/etc/do-run-firstboot')
