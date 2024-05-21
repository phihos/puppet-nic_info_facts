# nic_info_facts

Augment your facts with vendor and device info for each interface.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with nic_info_facts](#setup)
    * [What nic_info_facts affects](#what-nic_info_facts-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with nic_info_facts](#beginning-with-nic_info_facts)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

Puppet's default facts to not expose the model or vendor of a physical NIC.
This module fetches the vendor ID from `/sys/class/net/<interface>>/device/vendor` and the device ID from `/sys/class/net/eno1/device/device`.
Additionally it tries to resolve the vendor name and device (model) name from `/usr/share/misc/pci.ids`.
This approach is really fast compared to tools like `lshw` and does not require any additional binary.

## Setup

### Setup Requirements

Check which OS package provides `/usr/share/misc/pci.ids`. If not installed the fields `vendor_name` and `device_name` will be empty.

## Usage

Just install this module and `puppet facts | jq '.values.nic_info'` should show something like this:

```json
{
    "eno1": {
        "vendor_id": "0x8086",
        "device_id": "0x1563",
        "vendor_name": "Intel Corporation",
        "device_name": "Ethernet Controller X550"
    }
}
```
