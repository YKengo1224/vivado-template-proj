
from xml.etree import ElementTree as ET
import re

def param_val2int(val):
    match = re.match(r'0x([0-9A-Fa-f]+$)|0o([0-7]+$)|0b([01]+$)|([0-9]+$)', val)
    if match:
        if match.group(1) != None:
            num = int(match.group(1), 16)
        elif  match.group(2) != None:
            num = int(match.group(2), 8)
        elif  match.group(3) != None:
            num = int(match.group(3), 2)
        else:
            num = int(match.group(4), 10)
        return num
    return val

def parse(filename):
    tree = ET.parse(filename)
    root = tree.getroot()
    modules = root.find('MODULES').findall('MODULE')
    #print(modules)
    inst = {}
    hwinfo = {}
    for m in modules: 
        if ('xilinx.com:ip:zynq_ultra_ps_e' in m.attrib['VLNV']) or ('xilinx.com:ip:processing_system' in m.attrib['VLNV']):
            mmap = m.find('MEMORYMAP')
            for mem in mmap:
                inst[mem.attrib['INSTANCE']] = ''
            break

    for i in inst:
        for m in modules:
            if i == m.attrib['INSTANCE']:
                fullname = m.attrib['FULLNAME']
                inst[i] = fullname
                hwinfo[fullname] = {'params': {}}
                hwinfo[fullname]['fullname'] = fullname
                hwinfo[fullname]['instance'] = m.attrib['INSTANCE']
                vlnv = m.attrib['VLNV'].split(':')
                hwinfo[fullname]['vendor'] = vlnv[0]
                hwinfo[fullname]['library'] = vlnv[1]
                hwinfo[fullname]['name'] = vlnv[2]
                hwinfo[fullname]['version'] = vlnv[3]
                hwinfo[fullname]['vlnv'] = m.attrib['VLNV']
                for p in m.find('PARAMETERS'):
                    hwinfo[fullname]['params'][p.attrib['NAME']] = param_val2int(p.attrib['VALUE'])
                break
    return inst, hwinfo
