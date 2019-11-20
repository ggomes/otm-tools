from otm.OSMLoader import OSMLoader
import pickle

osmtool = OSMLoader()
osmtool.load_from_osm(
    north=38, 
	west=-122-(17/60)-(39.22/3600),
	south=37+(51/60)+(50.40/3600),
	east=-122-(16/60)-(2.24/3600),
    simplify_roundabouts=False
)

# X = osmtool.get_link_table()
# X.sort_values(by='travel_time', ascending=True, inplace=True)
# print(X)

# osmtool.merge_nodes([])

osmtool.save_to_xml('berkeley.xml')

print('DONE')


