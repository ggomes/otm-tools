from . import osm_query
from lxml import etree
import pandas as pd

road_param_types = {
    'residential':      {'id': 0, 'capacity': 2000, 'speed': 100, 'jam_density': 100},
    'tertiary':         {'id': 1, 'capacity': 2001, 'speed': 101, 'jam_density': 101},
    'tertiary_link':    {'id': 2, 'capacity': 2002, 'speed': 102, 'jam_density': 102},
    'unclassified':     {'id': 3, 'capacity': 2003, 'speed': 103, 'jam_density': 103},
    'secondary':        {'id': 4, 'capacity': 2004, 'speed': 104, 'jam_density': 104},
}

class OSMLoader:

    def __init__(self, cfg=''):
        self.config_file = cfg
        self.scenario = {}

    def load_from_osm(self,west=-122.2981,north=37.8790,east=-122.2547,south=37.8594,fixes={},simplify_roundabouts=False):
        self.scenario = osm_query.load_from_osm(west=west,north=north,east=east,south=south,fixes=fixes,simplify_roundabouts=simplify_roundabouts)

    def get_link_table(self):
        link_ids = []
        link_lengths = []
        travel_time = []
        speed_kph = []
        for link in self.scenario['links'].values():
            link_ids.append(link['id'])
            link_lengths.append(link['length'])
            speed = next(iter(set([rp['speed'] for rp in road_param_types.values() if rp['id']==link['roadparam']])))
            speed_kph.append(speed)
            travel_time.append(link['length']*3.6/speed)

        return pd.DataFrame(data={'id':link_ids,'length':link_lengths,'speed_kph':speed_kph,'travel_time':travel_time})

    def join_links_shorter_than(self, min_length_meters):

        while True:

            # find a candidate link
            short_links = [link for (linkid, link) in self.scenario['links'].items() if
                           link['length'] < min_length_meters and
                           ( len(self.scenario['nodes'][link['start_node_id']]['in_links'])==1 or
                           len(self.scenario['nodes'][link['end_node_id']]['out_links']) == 1 ) ]

            if len(short_links)==0:
                break

            foundone = False
            for short_link in short_links:

                start_node = self.scenario['nodes'][short_link['start_node_id']]
                end_node = self.scenario['nodes'][short_link['end_node_id']]

                # check the upstream link
                if len(start_node['in_links'])==1:
                    merge_link = self.scenario['links'][next(iter(start_node['in_links']))]

                    # merge if they have the same number of lanes
                    if merge_link['lanes']==short_link['lanes']:

                        merge_link['length'] = merge_link['length'] + short_link['length']
                        merge_link['end_node_id'] = short_link['end_node_id']
                        merge_link['nodes'] = merge_link['nodes'] + short_link['nodes'][1:]
                        del self.scenario['links'][short_link['id']]

                        if short_link['id'] in end_node['in_links']:
                            end_node['in_links'].remove(short_link['id'])

                        start_node['in_links'] = set()
                        start_node['out_links'] = set()
                        end_node['in_links'].add(merge_link['id'])
                        if start_node['id'] in self.scenario['external_nodes']:
                            self.scenario['external_nodes'].remove(start_node['id'])
                        self.scenario['internal_nodes'].add(start_node['id'])
                        foundone = True
                        break

                # check the downstream link
                else:
                    merge_link = self.scenario['links'][next(iter(end_node['out_links']))]

                    # merge if they have the same number of lanes
                    if merge_link['lanes']==short_link['lanes']:
                        merge_link['length'] = merge_link['length'] + short_link['length']
                        merge_link['start_node_id'] = short_link['start_node_id']
                        merge_link['nodes'] = short_link['nodes'] + merge_link['nodes'][1:]
                        del self.scenario['links'][short_link['id']]

                        if short_link['id'] in start_node['out_links']:
                            start_node['out_links'].remove(short_link['id'])
                        end_node['in_links'] = set()
                        end_node['out_links'] = set()
                        start_node['out_links'].add(merge_link['id'])
                        if end_node['id'] in self.scenario['external_nodes']:
                            self.scenario['external_nodes'].remove(end_node['id'])
                        self.scenario['internal_nodes'].add(end_node['id'])
                        foundone = True
                        break

            # if you go through all short_links and find nothing, then quit
            if not foundone:
                break

        print(len(self.scenario['links']))

    def merge_nodes(self, merge_nodes):

        # checks ...............
        for merge_node in merge_nodes:

            # check: merge_nodes in nodes
            if merge_node not in self.scenario['nodes']:
                print("ERROR: Bad node id " + merge_node)
                continue

            # check: merge_node joined by single link to another merge node
            node = self.scenario['nodes'][merge_node]

            links = node['in_links'].union(node['out_links'])

            print(links)

    def save_to_xml(self, outfile):

        scenario=etree.Element('scenario')
        scenario.set('xmlns','opentrafficmodels')
        etree.SubElement(scenario,'commodities')
        models = etree.SubElement(scenario, 'models')
        model = etree.SubElement(models,'model',{'type':'ctm','name':'myctm','is_default':'true'})
        etree.SubElement(model,'model_params',{'sim_dt':'2','max_cell_length':'100'})

        # vehicle types ............................
        commodities=next(scenario.iter('commodities'))
        etree.SubElement(commodities, 'commodity', {'id':'0','name':'type0','pathfull':'false'})

        # network ..................................
        network=etree.SubElement(scenario, 'network')

        # road params ..............................
        road_params=etree.SubElement(network,'roadparams')
        for road_type_name,road_type_params in road_param_types.items():
            etree.SubElement(road_params,'roadparam',{
                'id':str(road_type_params['id']),
                'capacity':str(road_type_params['capacity']),
                'speed':str(road_type_params['speed']),
                'jam_density':str(road_type_params['jam_density'])
            })

        # get all node positions ......................
        # node_id_map={}
        node_set=etree.SubElement(network,'nodes')
        node_id=0
        for node_osmid in self.scenario['external_nodes']:
            node = self.scenario['nodes'][node_osmid]
            # node_id_map[node['id']]=node_osmid
            etree.SubElement(node_set,'node',{
                'id':str(node_osmid),
                'x':'{:.2f}'.format(node['x']),
                'y':'{:.2f}'.format(node['y'])
            })
            node_id+=1

        link_id_map={}
        link_set=etree.SubElement(network,'links')
        link_id=0
        for link_osmid,link in self.scenario['links'].items():
            link_id_map[str(link['id'])]=link_id

            if link['start_node_id'] not in self.scenario['nodes'].keys():
                print('ERROR: link[start_node_id] not in nodes.keys()')

            if link['end_node_id'] not in self.scenario['nodes'].keys():
                print('ERROR: link[end_node_id] not in nodes.keys()')

            elink=etree.SubElement(link_set,'link',{
                'id':str(link_osmid),
                'length':'{:.2f}'.format(link['length']),  # WHAT UNITS IS THIS IN?
                'full_lanes':str(link['lanes']),  # HOW TO GET THE LANES?
                'start_node_id':str(link['start_node_id']),
                'end_node_id':str(link['end_node_id']),
                'roadparam':str(link['roadparam'])
            })
            link_id+=1

            epoints=etree.SubElement(elink,'points')
            for node_id in link['nodes']:
                node=self.scenario['nodes'][node_id]
                etree.SubElement(epoints,'point',{
                    'x':'{:.2f}'.format(node['x']),
                    'y':'{:.2f}'.format(node['y'])
                })

        # road connections ....................................
        rc_id=0
        roadconnections=etree.SubElement(network,'roadconnections')

        for road_conn in self.scenario['road_conns']:
            rc=etree.SubElement(roadconnections,'roadconnection',{
                'id':str(rc_id),
                'in_link':str(road_conn['in_link']),
                'out_link':str(road_conn['out_link']),
            })
            if 'in_link_lanes' in road_conn:
                rc['in_link_lanes']='{}#{}'.format(min(road_conn['in_link_lanes']),max(road_conn['in_link_lanes']))
            if 'out_link_lanes' in road_conn:
                rc['out_link_lanes']='{}#{}'.format(min(road_conn['out_link_lanes']),max(road_conn['out_link_lanes']))
            rc_id+=1

        # actuators .............................
        actuators=etree.SubElement(scenario,'actuators')

        # nodes_with_signals = [node for node in self.scenario['nodes'].values() if node['type']=='traffic_signals']
        actuator_id = 0
        for node in self.scenario['nodes'].values():

            if node['type']=='traffic_signals':

                in_links = [self.scenario['links'][link_id] for link_id in node['in_links']]
                road_conns = [road_conn for road_conn in self.scenario['road_conns'] if road_conn['in_link'] in node['in_links']]

                ### FIGURE OUT PHASES / ROAD CONNECTIONS

                actuator=etree.SubElement(actuators,'actuator',{'id':str(actuator_id),'type':'signal'})
                etree.SubElement(actuator,'actuator_target',{'type':'node','id':str(node['id'])})
                signal = etree.SubElement(actuator,'signal')

            if node['type']=='stop':
                actuator=etree.SubElement(actuators,'actuator',{'id':str(actuator_id),'type':'stop'})
                etree.SubElement(actuator,'actuator_target',{'type':'node','id':str(node['id'])})


            actuator_id += 1

        # # SUBNETWORK DATA
        # subnetworks = SubElement(scenario, 'subnetworks')
        # # zip all edge ids to their respective subnetwork ids
        # subnet_pairs = [(graph.edges[edge]['link_id'], graph.edges[edge]['subnetwork_id']) for edge in graph.edges]
        # distinct_subnets = set(list(zip(*subnet_pairs))[1])
        #
        # for subnet_id in distinct_subnets:
        #     subnet_links = sorted([i[0] for i in subnet_pairs if i[1] == subnet_id])
        #     subnetwork = SubElement(subnetworks, 'subnetwork', {'id': str(subnet_id)})
        #     subnetwork.text = ','.join([str(i) for i in subnet_links])

        with open(outfile,'wb') as xml_file:
            xml_file.write(etree.tostring(scenario,pretty_print=True))
