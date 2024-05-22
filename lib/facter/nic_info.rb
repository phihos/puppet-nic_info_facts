# frozen_string_literal: true

Facter.add(:nic_info) do
  confine :kernel do |value|
    value.casecmp('linux').zero?
  end

  def parse_pci_id_database(db_content)
    result = {}
    current_vendor_id = nil
    current_vendor = nil
    db_content.split("\n").each do |line|
      if line.start_with?("\t\t")
        # case 1: subvendor
        # we ignore subvendors
        next
      elsif line.start_with?("\t")
        # case 2: device of current vendor
        # parse ID and name and create a leaf entry in our data structure
        device_id, device_name = line.strip.split('  ', 2)
        result[current_vendor_id][device_id] = {
          'vendor_name' => current_vendor,
          'device_name' => device_name,
        }
      elsif %r{^[0-9]}.match?(line)
        # case 3: vendor
        # parse ID and name and create an inner node in our data structure
        current_vendor_id, current_vendor = line.strip.split('  ', 2)
        result[current_vendor_id] = {}
      else
        # case 4: other lines
        # we ignore other lines
        next
      end
    end
    result
  end

  def model_from_ids(vendor_id, device_id)
    pci_id_database_path = '/usr/share/misc/pci.ids'
    return '', '' unless File.file?(pci_id_database_path)
    pci_id_database_content = File.read(pci_id_database_path)
    pci_id_database = parse_pci_id_database(pci_id_database_content)
    vendor_id_without_hex_prefix = vendor_id.gsub('0x', '').downcase
    device_id_without_hex_prefix = device_id.gsub('0x', '').downcase
    database_lookup = pci_id_database.dig(vendor_id_without_hex_prefix, device_id_without_hex_prefix)
    return database_lookup['vendor_name'], database_lookup['device_name'] if database_lookup

    ['', '']
  end

  setcode do
    result = {}
    Facter.value(:networking)['interfaces'].each do |interface, _|
      sys_path_prefix = "/sys/class/net/#{interface}"
      vendor_id_path = "#{sys_path_prefix}/device/vendor"
      device_id_path = "#{sys_path_prefix}/device/device"
      unless File.file?(vendor_id_path) && File.file?(device_id_path)
        next
      end

      vendor_id = File.read(vendor_id_path).strip
      device_id =  File.read(device_id_path).strip
      vendor_name, device_name = model_from_ids(vendor_id, device_id)

      result[interface] = {
        'vendor_id' => vendor_id,
        'device_id' => device_id,
        'vendor_name' => vendor_name,
        'device_name' => device_name,
      }
    end

    result
  end
end
