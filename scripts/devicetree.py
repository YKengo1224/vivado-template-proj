# Device tree Simple Parser
# (C) 2023 Shibata Lab.

def load(in_data):
    nodes = {}
    state = 'normal'
    buf = ''
    buf_c = ''
    label_f = False
    label_name = ''
    node_name = ''
    unit_addr_f = False
    parent = None
    prop_f = False
    prop_name = ''
    line_num = 1

    for c in in_data:
        if c == '\n':
            line_num += 1
        if state == 'comment':
            buf_c += c
            if buf_c[-2:] == '*/':
                state = 'normal'
                buf_c = ''
        else:
            buf += c
            if buf[-2:] == '/*':
                state = 'comment'
                buf = buf[:-2]
                buf_c = ''
            elif buf[-2:] == '*/':
                print('Parse err: {}'.format(buf))
                exit(1)
            elif c == ';':
                if buf.strip()[-2] != '}' and parent != None:
                    if prop_f:
                        nodes[parent]['props'][prop_name] = buf[:-1].strip()
                    else:
                        nodes[parent]['props'][buf[:-1].strip()] = None
                label_f = False
                unit_addr_f = False
                prop_f = False
                buf = ''
            elif c == ':':
                label_f = True
                label_name = buf[:-1].strip()
                buf = ''
            elif c == '@':
                unit_addr_f = True
                node_name = buf[:-1].strip()
                buf = ''
            elif c == '{':
                label_name = label_name if label_f else None
                node_name = node_name if unit_addr_f else buf[:-1].strip()
                unit_addr = buf[:-1].strip() if unit_addr_f else None
                if label_f:
                    key = label_name
                elif unit_addr_f:
                    key = f'{node_name}@{unit_addr}'
                else:
                    key = node_name
                nodes[key] = {
                    'parent': parent,
                    'label': label_name,
                    'name': node_name,
                    'unit_addr': unit_addr,
                    'props': {},
                    'children': []
                    }
                if parent != None:
                    nodes[parent]['children'].append(key)
                label_f = False
                unit_addr_f = False
                prop_f = False
                parent = key
                buf = ''
            elif c == '}':
                parent = nodes[parent]['parent']
            elif c == '=':
                prop_f = True
                prop_name = buf[:-1].strip()
                buf = ''
    return nodes


def dump(nodes, node='&fpga_full', overlay=True, depth=0):
    if node == '&fpga_full' or node == '/':
        out_data = '/dts-v1/;\n'
        if overlay == True:
            out_data += '/plugin/;\n'
    else:
        out_data = ''
    n_name = nodes[node]['name']
    if nodes[node]['label'] != None:
        n_name = nodes[node]['label'] + ': ' + n_name
    if nodes[node]['unit_addr'] != None:
        n_name = n_name + '@' + nodes[node]['unit_addr']
    out_data += (' ' * 4 * depth) + n_name + ' {\n'

    props = nodes[node]['props']
    indent = ' ' * 4 * (depth + 1)
    for p in props:
        if props[p] == None:
            out_data += indent + p + ';\n'
        else:
            out_data += indent + p + ' = ' + props[p] + ';\n'
    for c in nodes[node]['children']:
        out_data += dump(nodes, node=c, depth=depth+1)
    out_data += (' ' * 4 * depth) +  '};\n'
    return out_data
