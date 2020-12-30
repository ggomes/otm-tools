from pyotm.OSMLoader import OSMLoader
import pickle

osmtool = OSMLoader()
osmtool.load_from_osm(
    west=-122.2981, north=37.8790, east=-122.2547, south=37.8594,
    exclude_tertiary=False,
    fixes={
        # turns: left | | | lanes 3
        # OSM: https://www.openstreetmap.org/way/415803770#map=19/37.87693/-122.28277
        # Google: https://www.google.com/maps/@37.8768752,-122.2828014,76m/data=!3m1!1e3
        # Correction: Turn includes the parking lane. Ignore it
        415803770: [('turn:lanes','left||')],

        # turns: left | through | through lanes 2
        # OSM: https://www.openstreetmap.org/way/415876791#map=19/37.87453/-122.26411
        # Google: https://www.google.com/maps/@37.8745003,-122.2648584,78a,35y,94.72h,32.94t/data=!3m1!1e3
        # Correction: Missing lane
        415876791: [('lanes',3),('lanes:backward',2),('turn:lanes:backward','|')],

        # Hearst @ LeConte
        # turns: left | through | through lanes 2
        # OSM: https://www.openstreetmap.org/way/574381942#map=19/37.87458/-122.26374
        # Google: https://www.google.com/maps/@37.8745017,-122.2643212,88m/data=!3m1!1e3
        # Correction: lanes -> 3
        574381942: [('lanes',3),('lanes:backward',2),('turn:lanes:backward','|')]
    }
)

# osmtool.simplify_roundabouts()

# osmtool.join_links_shorter_than(500.0)

# osmtool.merge_nodes([243670960, 53085601, 243670958])

# osmtool.set_demands_per_commodity_and_source_vph(demand)

osmtool.set_model({
    'type' : 'ctm',
    'sim_dt' : '2',
    'max_cell_length' : '100'})

osmtool.save_to_xml('berkeley_large.xml')

print('DONE')
