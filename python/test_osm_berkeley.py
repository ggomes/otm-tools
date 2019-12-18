from otm.OSMLoader import OSMLoader

osmtool = OSMLoader()
osmtool.load_from_osm(
    north= 37 + (52/60) + (44.11/3600),
    west= -122 - (17/60) - (31.01/3600),
    south= 37 + (51/60) + (47.76/3600),
    east= -122 - (15/60) - (10.83/3600),
    exclude_tertiary=False
)

osmtool.save_to_xml('berkeley2.xml')
