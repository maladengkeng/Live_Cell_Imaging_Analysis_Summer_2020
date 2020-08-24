# -*- coding: utf-8 -*-
"""
Created on Mon Aug 17 16:37:39 2020

@author: wjwesselink
"""
# Imports.
import sys
import stepfinder#lcapy.stepfinder
import matplotlib.pyplot as plt
import numpy as np
from file import parse_xml_table, create_xml_table
from stepfinder import find_steps, running_mean
#%%
##########################################
# Begin 
sys.path.append(r'C:\Users\wjwesselink\Desktop\Python')
root_directory = r'M:\tnw\bn\nd\Shared\Wouter\photobleaching\21082020\hilo\Test_2'

exposure_time = 0.075 # s
time_between_exposures = 0.025 # s
photoncalibration_offset = -87.48 # ADU ( = bias offset )
photoncalibration_factor = 5.03 / 300 / 0.90 # ) = x pre_amp / multiplier / QE )

min_step_size = 1 # photons (for step_finder)
min_plateau_length = 1 # s (for step_finder)


# End edit
##########################################
#%%
# Load and parse xml table to dataframe


if not 'df_spots' in locals():
    df_xmls = create_xml_table(root_directory)
    df_spots = parse_xml_table(df_xmls)

track_num = 1 # No. 1 has most data points, last frame has fewest

# Convert dataframe to numpy array
frame = np.array([])
track_id = np.array([])
intensity = np.array([])
data_point_count = np.array([])
num_steps = np.array([])
step_sizes_list = np.array([])

for ii in range(0, df_spots.shape[0]):
    frame = np.append(frame,df_spots.iloc[ii,1])
    track_id = np.append(track_id,df_spots.iloc[ii,2])
    intensity = np.append(intensity,df_spots.iloc[ii,5])

# Preselect traces with most data
for ii in range(min(track_id).astype(int),max(track_id).astype(int)):
    data_point_count = np.append(data_point_count, (frame[np.where(track_id == ii)]).size)
sorting_array = np.flip(np.argsort(data_point_count))

# Select trace
trace_list = np.unique(track_id)
intensity_i = intensity[np.where(track_id.astype(int) == trace_list[track_num])]
intensity_i = (intensity_i + photoncalibration_offset) * photoncalibration_factor
frame_i = frame[np.where(track_id == trace_list[track_num])]
find_steps(frame_i, intensity_i, trace_list[track_num])

# Fit steps to data
y = running_mean(intensity_i, 2)
x = frame_i * (exposure_time + time_between_exposures)
step_locs, step_sizes, step_y = stepfinder.find_steps(x, y, 150, 1)

# Display results
fig = plt.figure(figsize=(12, 5))
plt.plot(x,intensity_i, alpha=0.2, c='k')
plt.plot(x,y)
plt.plot(x,step_y)
plt.xlabel('Time (s)')
plt.ylabel('Intensity (photons)')
title_str = "Fitted intensity trail " + str(track_num) + ", " + str(step_locs.shape[0]+1) + " steps fitted"
plt.title(title_str)
plt.close()
fig

#%%
# Retrieve information on all traces
frame = np.array([])
track_id = np.array([])
intensity = np.array([])
data_point_count = np.array([])
num_steps = np.array([])
step_sizes_list = np.array([])

for ii in range(0, df_spots.shape[0]):
    frame = np.append(frame,df_spots.iloc[ii,1])
    track_id = np.append(track_id,df_spots.iloc[ii,2])
    intensity = np.append(intensity,df_spots.iloc[ii,5])

for ii in range(min(track_id).astype(int),max(track_id).astype(int)):
    num_frame = sorting_array[ii]
    intensity_i = intensity[np.where(track_id == num_frame)]
    intensity_i = (intensity_i + photoncalibration_offset) * photoncalibration_factor
    frame_i = frame[np.where(track_id == num_frame)]
    find_steps(frame_i, intensity_i, num_frame)
    
    # Fit steps to data
    y = running_mean(intensity_i, 3)
    x = frame_i * (exposure_time + time_between_exposures)
    step_locs, step_sizes, step_y = stepfinder.find_steps(x, y, 60, 2)
    
    if len(step_locs) > 0:
        num_steps = np.append(num_steps, step_locs.shape[0])
        
    if len(step_sizes) > 0:
        step_sizes_list = np.append(step_sizes_list, step_sizes)

fig = plt.figure(figsize=(12, 5))
plt.hist(num_steps+1, bins=25)
plt.gca().set(title='Step frequency', ylabel='Frequency', xlabel = 'Number of steps');   
plt.close()
fig

fig = plt.figure(figsize=(12, 5))
plt.hist(step_sizes_list, bins=50)
plt.gca().set(title='Step sizes', ylabel='Frequency', xlabel = 'Step size (photons)');   
plt.close()
fig
