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

osmtool.save_to_xml('berkeley2.xml')

print('DONE')


