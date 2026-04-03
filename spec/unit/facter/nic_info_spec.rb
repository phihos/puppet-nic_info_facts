# frozen_string_literal: true

require 'spec_helper'
require 'facter'
require 'facter/nic_info'

describe :nic_info, type: :fact do
  subject(:fact) { Facter.fact(:nic_info) }

  let(:pci_ids_content) { File.read(File.join(__dir__, 'pci.ids')) }
  let(:expected_result) do
    {
      'eno1' => {
        'vendor_id' => '0x8086',
        'device_id' => '0x1563',
        'vendor_name' => 'Intel Corporation',
        'device_name' => 'Ethernet Controller X550',
      }
    }
  end

  before :each do
    Facter.clear
    allow(Facter.fact(:networking)).to receive(:value).and_return(
      {
        'interfaces' => {
          'eno1' => {},
        }
      },
    )
    allow(File).to receive(:file?).and_call_original
    allow(File).to receive(:file?).with('/sys/class/net/eno1/device/vendor').and_return(true)
    allow(File).to receive(:file?).with('/sys/class/net/eno1/device/device').and_return(true)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with('/sys/class/net/eno1/device/vendor').and_return('0x8086')
    allow(File).to receive(:read).with('/sys/class/net/eno1/device/device').and_return('0x1563')
  end

  context 'when pci.ids is at /usr/share/misc/pci.ids' do
    before :each do
      allow(File).to receive(:file?).with('/usr/share/misc/pci.ids').and_return(true)
      allow(File).to receive(:read).with('/usr/share/misc/pci.ids', encoding: 'UTF-8').and_return(pci_ids_content)
    end

    it 'returns a value' do
      expect(fact.value).to eq(expected_result)
    end
  end

  context 'when pci.ids is at /usr/share/hwdata/pci.ids' do
    before :each do
      allow(File).to receive(:file?).with('/usr/share/misc/pci.ids').and_return(false)
      allow(File).to receive(:file?).with('/usr/share/hwdata/pci.ids').and_return(true)
      allow(File).to receive(:read).with('/usr/share/hwdata/pci.ids', encoding: 'UTF-8').and_return(pci_ids_content)
    end

    it 'returns a value' do
      expect(fact.value).to eq(expected_result)
    end
  end

  context 'when pci.ids is not found' do
    before :each do
      allow(File).to receive(:file?).with('/usr/share/misc/pci.ids').and_return(false)
      allow(File).to receive(:file?).with('/usr/share/hwdata/pci.ids').and_return(false)
    end

    it 'returns empty vendor and device names' do
      expect(fact.value).to eq({
                                 'eno1' => {
                                   'vendor_id' => '0x8086',
                                   'device_id' => '0x1563',
                                   'vendor_name' => '',
                                   'device_name' => '',
                                 }
                               })
    end
  end
end
