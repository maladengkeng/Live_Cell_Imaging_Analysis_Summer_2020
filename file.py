import pandas as pd
import xml.etree.ElementTree
import os
import glob

#from ctrappy.image import Image
import numpy as np


def parse_xml_table(df, only_tracks=True, filtered_tracks_only=True):
    """Parse xml table, file by file; return dataframe with spots and tracks."""
    df_out = pd.DataFrame()
    for i, row in df.iterrows():
        df_trace = parse_xml(row['path'],
                             only_tracks=only_tracks, filtered_tracks_only=filtered_tracks_only)
        df_trace['xml_path'] = row['path']
        df_out = df_out.append(df_trace, ignore_index=True)
    # df_out = df_out[['experiment_id', 'xml_path', 'frame', 'track_id', 'color', 'x', 'y',
    #                  'intensity', 'spot_id', 'spot_id_from', 'spot_id_to']]
    df_out = df_out[['xml_path', 'frame', 'track_id','x', 'y',
                     'intensity', 'spot_id', 'dna_start', 'dna_end']]
    df_out['frame'] = df_out['frame'].astype(int)
    # df_out['track_id'] = df_out['track_id'].astype(int)
    return df_out


def parse_xml(path, only_tracks=True, filtered_tracks_only=True):
    """Parse xml file.

    Parameters
    ----------
    path : str
        Path to input xml file.
    color : str
        Either 'r', 'g', or 'b'.
    only_tracks : bool
        Parse only those spots that are in tracks. If False, parse all spots with VISIBLE="1".

    Returns
    -------
    df_out : pandas DataFrame
        Table containing spots.
    """

    # Open xml file.
    xtree = xml.etree.ElementTree.parse(path)
    xroot = xtree.getroot()

    # Get dna start and dna end.
    df_spots = pd.DataFrame()
    x_start = -1
    x_end = -1
    for node in xroot.iter('Log'):
        log_text = node.text
        for line in log_text.split('\n'):
            if line.startswith("x0: "):
                x_start = line.split(": ")[1]
            elif line.startswith("x1: "):
                x_end = line.split(": ")[1]
    x_start = float(x_start)
    x_end = float(x_end)
    if x_start == -1:
        x_start = np.nan
    if x_end == -1:
        x_end = np.nan

    # Fill spot table.
    for node in xroot.iter('Spot'):
        spot_id = int(node.attrib['ID'])
        frame = int(node.attrib['FRAME'])
        x = float(node.attrib['POSITION_X'])
        y = float(node.attrib['POSITION_Y'])
        intensity = float(node.attrib['TOTAL_INTENSITY'])
        visible = int(node.attrib['VISIBILITY'])
        append_dict = {'spot_id': spot_id,
                       'frame': frame,
                       'x': x,
                       'y': y,
                       'intensity': intensity,
                       'visible': visible}
        df_spots = df_spots.append(append_dict, ignore_index=True)
    if df_spots.empty:
        return pd.DataFrame()
    df_spots['frame'] = df_spots['frame'].astype(int)
    df_spots['spot_id'] = df_spots['spot_id'].astype(int)
    df_spots['dna_start'] = float(x_start)
    df_spots['dna_end'] = float(x_end)

    # Fill track table.
    df_tracks = pd.DataFrame()
    for node in xroot.iter('Track'):
        track_id = int(node.attrib['TRACK_ID'])
        for child in node:
            spot_id0 = int(child.attrib['SPOT_SOURCE_ID'])
            spot_id1 = int(child.attrib['SPOT_TARGET_ID'])
            append_dict0 = {'track_id': track_id,
                            'spot_id': spot_id0}
            append_dict1 = {'track_id': track_id,
                            'spot_id': spot_id1}
            df_tracks = df_tracks.append(append_dict0, ignore_index=True)
            df_tracks = df_tracks.append(append_dict1, ignore_index=True)
    if df_tracks.empty and only_tracks:
        return pd.DataFrame()
    if df_tracks.empty and not only_tracks:
        df_out = df_spots[df_spots['visible'] == 1].copy()
        df_out['track_id'] = np.nan
        return df_out

    # Filtered tracks.
    df_filtered_tracks = pd.DataFrame()
    for node in xroot.iter('TrackID'):
        track_id = int(node.attrib['TRACK_ID'])
        append_dict = {'track_id': track_id}
        df_filtered_tracks = df_filtered_tracks.append(append_dict, ignore_index=True)
    if filtered_tracks_only:
        if df_filtered_tracks.empty:
            return pd.DataFrame()
        else:
            df_tracks = df_tracks.merge(df_filtered_tracks, left_on='track_id', right_on='track_id', how='inner')

    # # Fill track table (with merging/splitting).
    # df_tracks_from = pd.DataFrame()
    # df_tracks_to = pd.DataFrame()
    # for node in xroot.iter('Track'):
    #     track_id = int(node.attrib['TRACK_ID'])
    #     for child in node:
    #         spot_id0 = int(child.attrib['SPOT_SOURCE_ID'])
    #         spot_id1 = int(child.attrib['SPOT_TARGET_ID'])
    #         append_dict_from = {'track_id': track_id,
    #                             'spot_id': spot_id1,
    #                             'spot_id_from': spot_id0}
    #         append_dict_to = {'spot_id': spot_id0,
    #                           'spot_id_to': spot_id1}
    #         df_tracks_from = df_tracks_from.append(append_dict_from, ignore_index=True)
    #         df_tracks_to = df_tracks_to.append(append_dict_to, ignore_index=True)
    # if (df_tracks_from.empty or df_tracks_to.empty) and only_tracks:
    #     return pd.DataFrame()
    # if (df_tracks_from.empty or df_tracks_to.empty) and not only_tracks:
    #     df_out = df_spots[df_spots['visible'] == 1].copy()
    #     df_out['track_id'] = np.nan
    #     df_out['spot_id_from'] = np.nan
    #     df_out['spot_id_to'] = np.nan
    #     return df_out
    # df_tracks = df_tracks_from.merge(df_tracks_to, left_on='spot_id', right_on='spot_id', how='outer')

    # df_tracks['track_id'] = df_tracks['track_id'].astype(int)
    df_tracks['spot_id'] = df_tracks['spot_id'].astype(int)
    df_tracks = df_tracks.drop_duplicates(['spot_id'])

    # Combine tables into dataframe with locations of tracked spots.
    if only_tracks:
        df_out = df_tracks.merge(df_spots, left_on='spot_id', right_on='spot_id', how='inner')
    else:
        df_spots = df_spots[df_spots['visible'] == 1]
        df_out = df_tracks.merge(df_spots, left_on='spot_id', right_on='spot_id', how='outer')
    df_out = df_out.sort_values(['frame', 'x'])
    # df_out = df_out[['frame', 'track_id', 'color', 'x', 'y', 'intensity', 'spot_id', 'spot_id_from', 'spot_id_to']]
    df_out = df_out[['frame', 'track_id', 'x', 'y', 'intensity', 'spot_id', 'dna_start', 'dna_end']]
    return df_out


def create_xml_table(root):
    """Create dataframe listing xml files.

    Parameters
    ----------
    root : str
        Root directory.
    subdir_list : list of strs
        Subdirectories containing subsubdirectories 'red', 'green' and 'blue', containing xml files.

    Returns
    -------
    df : pandas DataFrame
        DataFrame containing paths to xml files.
    """

    df = pd.DataFrame()
    xml_dir = root
    xml_list = glob.glob(os.path.join(xml_dir, '*.xml'))
    for xml_path in xml_list:
        append_dict = {'path': xml_path,
                      }
        df = df.append(append_dict, ignore_index=True)
    df['file_name'] = df['path'].apply(lambda x: x.split('/')[-1].split('\\')[-1])
    df = df[['path', 'file_name']]
    return df
