from otm.OSMLoader import OSMLoader
import pickle

osmtool = OSMLoader()
osmtool.load_from_osm(
    north=25.9841,
    south=25.1923,
    east=-80.1107,
    west=-80.8593,
    simplify_roundabouts=False,
    fixes={
    }
)

# X = osmtool.get_link_table()
# X.sort_values(by='travel_time', ascending=True, inplace=True)
# print(X)

# osmtool.merge_nodes([])

osmtool.save_to_xml('miami.xml')

print('DONE')
