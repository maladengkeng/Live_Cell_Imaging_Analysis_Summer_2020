import sys
import os
from ij import IJ
import glob
from ij.measure import Calibration
from loci.plugins import BF
from fiji.plugin.trackmate import Model
from fiji.plugin.trackmate import Settings
from fiji.plugin.trackmate import TrackMate
from fiji.plugin.trackmate import SelectionModel
from fiji.plugin.trackmate import Logger
from fiji.plugin.trackmate.detection import LogDetectorFactory
from fiji.plugin.trackmate.tracking import LAPUtils
from fiji.plugin.trackmate.tracking.sparselap import SparseLAPTrackerFactory
from fiji.plugin.trackmate.providers import SpotAnalyzerProvider
from fiji.plugin.trackmate.providers import EdgeAnalyzerProvider
from fiji.plugin.trackmate.providers import TrackAnalyzerProvider
from fiji.plugin.trackmate.features.spot import SpotIntensityAnalyzerFactory
import fiji.plugin.trackmate.visualization.hyperstack.HyperStackDisplayer as HyperStackDisplayer
import fiji.plugin.trackmate.features.FeatureFilter as FeatureFilter
from fiji.plugin.trackmate.action import ExportTracksToXML
import java.io.File as File
import fiji.plugin.trackmate.io.TmXmlWriter as TmXmlWriter
   
# Parameters
########## START EDITING
input_csv = '/home/edo/test_data/CTrap/ORC_kinetics/experiment_table.csv'
output_dir = '/home/edo/test_data/CTrap/MCM/Exp87_before_HSW/xmls_newparams/'
resolution = 0.050  # resolution of pixel in micron

spot_radius = [4, 4, 4]  # spot radius in pixels for r, g, b
spot_mean_intensity = [0.3, 0.3, 0.1]  # minimum mean intensity value for r, g, b
spot_standard_deviation = [0.6, 0.6, 0.2]  # minimum standard deviation of blobs for r, g, b

max_frame_gap = 4  # maximum gap (frames) for blob connection
linking_max_distance = 1.  # max distance (micron) for blob connection
gap_closing_max_distance = 1.  # max distance (micron) for gap closing
track_start = 5  # tracks need to start before this frame number
########## END EDITING

# Read experiment id csv.
f = open(input_csv, "r")
input_dirs = []
exp_ids = []
for i, line in enumerate(f):
	if i > 0:
		info = line.split(',')
		input_dirs.append(info[0])
		exp_ids.append(info[1])

# Iterate over input directories.
for input_dir, exp_id in zip(input_dirs, exp_ids):

	# Find input files.
	input_files = glob.glob(os.path.join(input_dir, "*.tiff"))
	input_files = input_files + glob.glob(os.path.join(input_dir, "*/", "*.tiff"))
	input_files = input_files + glob.glob(os.path.join(input_dir, "*/*/", "*.tiff"))
	input_files = input_files + glob.glob(os.path.join(input_dir, "*/*/*/", "*.tiff"))
	input_files = input_files + glob.glob(os.path.join(input_dir, "*/*/*/*/", "*.tiff"))
	input_files = input_files + glob.glob(os.path.join(input_dir, "*/*/*/*/*/", "*.tiff"))
	print "Files found for " + exp_id + ": " + str(input_files)
	colors = [1, 2, 3]
	str_colors = ['red', 'green', 'blue']
	directory = os.path.join(output_dir, exp_id)
	if not os.path.exists(directory):
		os.makedirs(directory)
	
	for input_file in input_files:
		for i_col, color in enumerate(colors):
			try:

				# Get metadata.
				metadata_file = input_file.replace(".tiff", "_metadata.txt")
				x_start = -1.
				x_end = -1.
				with open(metadata_file) as md:
					for line in md:
						if line.startswith("x0_dna: "):
							x_start = line.split(": ")[1]
						elif line.startswith("x1_dna: "):
							x_end = line.split(": ")[1]

				# Set output file.
				output_file = input_file.split('\\')[-1].split('/')[-1].split('.')[0] + '.xml'
				output_file = os.path.join(output_dir, exp_id, str_colors[i_col], output_file)
				directory = os.path.join(output_dir, exp_id, str_colors[i_col])
				if not os.path.exists(directory):
					os.makedirs(directory)
				output_file = os.path.join(directory, output_file)
				print "Processing: " + output_file
	
				# Add information to xml log.
				log_info = 'input: ' + input_file + '\n'
				log_info += 'output: ' + output_file + '\n'
				log_info += 'x0: ' + str(x_start) + '\n'
				log_info += 'x1: ' + str(x_end) + '\n'
				log_info += 'pixel size: ' + str(resolution) + '\n'
				log_info += 'spot_radius: ' + str(spot_radius[i_col]) + '\n'
				log_info += 'spot_mean_intensity: ' + str(spot_mean_intensity[i_col]) + '\n'
				log_info += 'spot_standard_deviation: ' + str(spot_standard_deviation[i_col]) + '\n'
				log_info += 'max_frame_gap: ' + str(max_frame_gap) + '\n'
				log_info += 'linking_max_distance: ' + str(linking_max_distance) + '\n'
				log_info += 'gap_closing_max_distance: ' + str(gap_closing_max_distance) + '\n'
				log_info += 'track_start: ' + str(track_start) + '\n'
			
				# Get image and calibrate
				imps = BF.openImagePlus(input_file)
				imp = imps[0]
				imp.setDisplayMode(IJ.COLOR)
				imp.setC(color)
				# imp.setDisplayRange(0.0, 3.0)
				# imp.show()
				
				log_info += 'frames: ' + str(imp.getNFrames()) + '\n'
				log_info += 'width: ' + str(imp.getWidth()) + '\n'
				log_info += 'height: ' + str(imp.getHeight()) + '\n'
				
				cal = Calibration()
				cal.setUnit('micron')
				cal.pixelHeight = resolution
				cal.pixelWidth = resolution
				cal.pixelDepth = 0.
				cal.fps = 1
				cal.frameInterval = 1
				imp.setCalibration(cal)
				   
				#-------------------------
				# Instantiate model object
				#-------------------------
				   
				model = Model()
				model.setPhysicalUnits( 'micron', 'frames' )
				   
				# Set logger
				model.setLogger(Logger.IJ_LOGGER)
				   
				#------------------------
				# Prepare settings object
				#------------------------
				      
				settings = Settings()
				settings.setFrom(imp)
				       
				# Configure detector - We use the Strings for the keys
				settings.detectorFactory = LogDetectorFactory()
				settings.detectorSettings = { 
				    'DO_SUBPIXEL_LOCALIZATION' : True,
				    'RADIUS' : spot_radius[i_col] * resolution,
				    'TARGET_CHANNEL' : color,
				    'THRESHOLD' : 0.000001,
				    'DO_MEDIAN_FILTERING' : True,
				}  
				    
				# Configure spot filters
				w = imp.getWidth()
				h = imp.getHeight()
				y_lims = (2, h-2)
				if w == 140:
				    x_lims = (8, 132)
				elif w == 180:
				    x_lims = (8, 160)
				elif w == 200:
				    x_lims = (41, 140)
				elif w == 220:
				    x_lims = (10, 160)
				elif w == 248:
				    x_lims = (85, 205)
				    y_lims = (25, 35)
				filter0 = FeatureFilter('MEAN_INTENSITY', spot_mean_intensity[i_col], True)
				filter1 = FeatureFilter('STANDARD_DEVIATION', spot_standard_deviation[i_col], True)
				filter2 = FeatureFilter('POSITION_X', x_lims[0] * resolution, True)
				filter3 = FeatureFilter('POSITION_X', x_lims[1] * resolution, False)
				filter4 = FeatureFilter('POSITION_Y', y_lims[0] * resolution, True)
				filter5 = FeatureFilter('POSITION_Y', y_lims[1] * resolution, False)
				settings.addSpotFilter(filter0)
				settings.addSpotFilter(filter1)
				settings.addSpotFilter(filter2)
				settings.addSpotFilter(filter3)
				settings.addSpotFilter(filter4)
				settings.addSpotFilter(filter5)
				     
				# Configure tracker - We want to disallow merges and fusions
				settings.trackerFactory = SparseLAPTrackerFactory()
				settings.trackerSettings = LAPUtils.getDefaultLAPSettingsMap()
				settings.trackerSettings['ALLOW_TRACK_SPLITTING'] = False
				settings.trackerSettings['ALLOW_TRACK_MERGING'] = False
				settings.trackerSettings['MAX_FRAME_GAP']  = max_frame_gap
				settings.trackerSettings['LINKING_MAX_DISTANCE']  = linking_max_distance
				# settings.trackerSettings['MERGING_MAX_DISTANCE']  = linking_max_distance
				# settings.trackerSettings['SPLITTING_MAX_DISTANCE']  = linking_max_distance
				settings.trackerSettings['GAP_CLOSING_MAX_DISTANCE']  = gap_closing_max_distance
				
				# Add ALL the feature analyzers known to TrackMate, via
				# providers. 
				# They offer automatic analyzer detection, so all the 
				# available feature analyzers will be added. 
				 
				spotAnalyzerProvider = SpotAnalyzerProvider()
				for key in spotAnalyzerProvider.getKeys():
				    # print( key )
				    settings.addSpotAnalyzerFactory( spotAnalyzerProvider.getFactory( key ) )
				 
				edgeAnalyzerProvider = EdgeAnalyzerProvider()
				for  key in edgeAnalyzerProvider.getKeys():
				    # print( key )
				    settings.addEdgeAnalyzer( edgeAnalyzerProvider.getFactory( key ) )
				 
				trackAnalyzerProvider = TrackAnalyzerProvider()
				for key in trackAnalyzerProvider.getKeys():
				    # print( key )
				    settings.addTrackAnalyzer( trackAnalyzerProvider.getFactory( key ) )
				    
				 
				# Configure track filters - track should start before frame 5
				track_filter = FeatureFilter('TRACK_START', track_start, False)
				settings.addTrackFilter(track_filter)
				
				#-------------------
				# Instantiate plugin
				#-------------------
				    
				trackmate = TrackMate(model, settings)
				       
				#--------
				# Process
				#--------
				    
				ok = trackmate.checkInput()
				if not ok:
				    sys.exit(str(trackmate.getErrorMessage()))
				    
				ok = trackmate.process()
				if not ok:
				    sys.exit(str(trackmate.getErrorMessage()))
				    
				       
				#----------------
				# Display results
				#----------------
				     
				selectionModel = SelectionModel(model)
				# displayer =  HyperStackDisplayer(model, selectionModel, imp)
				# displayer.render()
				# displayer.refresh()
				    
				# Echo results with the logger we set at start:
				model.getLogger().log(str(model))
				
				# Export
				outFile = File(output_file)
				writer = TmXmlWriter(outFile)
				writer.appendLog(log_info)
				writer.appendModel(model)
				writer.appendSettings(settings)
				writer.writeToFile()
			except:
				# Write empty error file.
				print('Error - writing error file...')
				output_file = input_file.split('\\')[-1].split('/')[-1].split('.')[0] + '_ERROR.txt'
				output_file = os.path.join(output_dir, exp_id, str_colors[i_col], output_file)
				file = open(output_file,"w") 
				file.close()
