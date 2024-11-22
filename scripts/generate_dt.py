import devicetree as dt
import hwh
import json
import sys

dtsi_file = sys.argv[1]
hwh_file = sys.argv[2]
out_dtsi_file = sys.argv[3]
out_hwh_file = sys.argv[4]
vivado_ver = sys.argv[5]

with open(dtsi_file) as f:
    dts = f.read()

nodes = dt.load(dts)
inst_list, hwinfo = hwh.parse(hwh_file)

frame_width = 1280
frame_height = 720

vfrmbuf_dmasize = lambda params: int(params["MAX_COLS"]) * int(params["MAX_ROWS"]) * int(params["NUM_VIDEO_COMPONENTS"])
axi_dmanum = lambda params: int(params["C_INCLUDE_S2MM"]) + int(params["C_INCLUDE_MM2S"])

compatible_list = {
    'xlnx,v-frmbuf-rd': {'dma': 1, 'dma_size': vfrmbuf_dmasize},
    'xlnx,v-frmbuf-wr': {'dma': 1, 'dma_size': vfrmbuf_dmasize},
    'xlnx,axi-dma-7': {'dma': axi_dmanum, 'dma_size': lambda _: 16*(2**20)},
    'xlnx,v-proc-ss': {'dma': 0, 'dma_size': lambda _: 0},
    'xlnx,umv-motor-controller': {'dma': 0, 'dma_size': lambda _: 0},
    'xlnx,umv-lane-detector': {'dma': 1, 'dma_size': lambda _: 4096},
    'xlnx,yolo-acc-top': {'dma': 0, 'dma_size': lambda _: 0},
    'xlnx,yolo-conv-top': {'dma': 0, 'dma_size': lambda _: 0},
    'xlnx,yolo-max-pool-top': {'dma': 0, 'dma_size': lambda _: 0},
    'xlnx,yolo-upsamp-top': {'dma': 0, 'dma_size': lambda _: 0},
    'xlnx,yolo-yolo-top': {'dma': 0, 'dma_size': lambda _: 0},
    'xlnx,axis-switch': {'dma': 0, 'dma_size': lambda _: 0},
    'xlnx,axi-gpio-2.0': {'dma': 0, 'dma_size': lambda _: 0},
    'xlnx,jpeg-encoder-1.0': {'dma': 0, 'dma_size': lambda _: 0},
}

delete_list = [
    'xlnx,pl-disp',
    'xlnx,video',
]


for n in list(nodes.keys()):
    props = nodes[n]['props']
    if 'compatible' in props:
        compatible = props['compatible']
        for d in delete_list:
            if d in compatible:
                nodes[nodes[n]['parent']]['children'].remove(n)
        for c in compatible_list:
            if c in compatible:
                fullname = inst_list[n]
                hwinfo[fullname]['uio'] = n
                nodes[n]['props']['linux,uio-name'] = f'"{n}"'
                nodes[n]['props'] = {k: v for k, v in props.items() if k[0:5] != 'xlnx,'}
                nodes[n]['props']['compatible'] = '"generic-uio"'
                nodes[n]['children'] = []
                dma_n = compatible_list[c]['dma']
                dma_num = dma_n if type(dma_n) == int else dma_n(hwinfo[fullname]['params'])
                if compatible_list[c]['dma'] != 0:
                    hwinfo[fullname]['udmabuf'] = []
                for i in range(dma_num):
                    udmabuf_name = 'udmabuf_{}_{}'.format(n, i)
                    udmabuf_size = compatible_list[c]['dma_size'](hwinfo[fullname]['params'])
                    nodes[nodes[n]['parent']]['children'].append(udmabuf_name)
                    hwinfo[fullname]['udmabuf'].append(udmabuf_name)
                    nodes[udmabuf_name] = {
                        'parent': nodes[n]['parent'],
                        'label': None,
                        'name': udmabuf_name,
                        'unit_addr': None,
                        'props': {
                            'compatible': '"ikwzm,u-dma-buf"',
				            'device-name': '"' + udmabuf_name + '"',
                            'size': '<' + hex(udmabuf_size) + '>'
                        },
                        'children': []
                    }

#print(nodes,node=nodes"&fpga_full")

if vivado_ver == "2022.1":
    out_data = dt.dump(nodes,node='/')
else :
    out_data = dt.dump(nodes,node="&fpga_full") + dt.dump(nodes,node="&amba")
    
with open(out_dtsi_file, 'w') as f:
    f.write(out_data)

with open(out_hwh_file, 'w') as f:
    json.dump(hwinfo, f, indent=2)
