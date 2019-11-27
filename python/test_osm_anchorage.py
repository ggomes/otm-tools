from otm.OSMLoader import OSMLoader

osmtool = OSMLoader()
osmtool.load_from_osm(
    north=61.2597,south=61.0672,east=-149.6302,west=-150.0446,
    simplify_roundabouts=False,
    fixes={
        # ERROR 'turn:lanes:both_ways' in tags and 'turn:lanes:forward' in tags
        # OSM: https://www.openstreetmap.org/way/651292620#map=18/61.13014/-149.88261
        # Google: https://www.google.com/maps/@61.1302853,-149.8829239,341m/data=!3m1!1e3
        651292620 : [('lanes:both_ways',None),('turn:lanes:both_ways',None)]
    }
)

# X = osmtool.get_link_table()
# X.sort_values(by='travel_time', ascending=True, inplace=True)
# print(X)

osmtool.save_to_xml('anchorage.xml')

print('DONE')

