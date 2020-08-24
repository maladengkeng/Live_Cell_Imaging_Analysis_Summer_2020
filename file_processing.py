import sys
import os
import imagej
ij = imagej.init('C:/Users/wjwesselink/Desktop/Fiji.app')
from ij import IJ
import glob
from ij.measure import Calibration
from loci.plugins import BF
from fiji.plugin.trackmate import Model
#conda activate imagej
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
input_files = ['M:/tnw/bn/nd/Shared/Wouter/photobleaching/GitHub/BEP_Mala/test_data/1002_c2']
write_to_file = False
out_file = '/home/edo/test_data/CTrap/simulated/green/test_splitmerge.xml'
resolution = 0.130  # resolution of pixel in micron

spot_radius = 4  # spot radius in pixels for r, g, b
spot_mean_intensity = 0.3  # minimum mean intensity value for r, g, b
spot_standard_deviation = 0.6  # minimum standard deviation of blobs for r, g, b

max_frame_gap = 2  # maximum gap (frames) for blob connection
linking_max_distance = 1.0  # max distance (micron) for blob connection
gap_closing_max_distance = 1.0  # max distance (micron) for gap closing
track_start = 5  # tracks need to start before this frame number
########## END EDITING

# Iterate over input files.
for input_file in input_files:
	
		# Get image and calibrate
		imps = BF.openImagePlus(input_file)
		imp = imps[0]
		imp.setDisplayMode(IJ.COLOR)
		imp.setDisplayRange(0.0, 3.0)
		imp.show()
		
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
		    'THRESHOLD' : 0.00001,
		    'DO_MEDIAN_FILTERING' : True,
		}  
		    
		# Configure spot filters - Classical filter on quality
		w = imp.getWidth()
		h = imp.getHeight()
		y_lims = (int(h*0.5)-3, int(h*0.5)+3)
		if w == 140:
		    x_lims = (8, 132)
		elif w == 180:
		    x_lims = (8, 160)
		elif w == 200:
		    x_lims = (41, 140)
		elif w == 220:
		    x_lims = (10, 160)
		elif w == 248:
		    x_lims = (80, 200)
		    y_lims = (30, 36)
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
		# See https://javadoc.scijava.org/Fiji/index.html?constant-values.html
		settings.trackerFactory = SparseLAPTrackerFactory()
		settings.trackerSettings = LAPUtils.getDefaultLAPSettingsMap()
		settings.trackerSettings['ALLOW_TRACK_SPLITTING'] = True
		settings.trackerSettings['ALLOW_TRACK_MERGING'] = True
		settings.trackerSettings['MAX_FRAME_GAP']  = max_frame_gap
		settings.trackerSettings['LINKING_MAX_DISTANCE']  = linking_max_distance
		settings.trackerSettings['MERGING_MAX_DISTANCE']  = linking_max_distance
		settings.trackerSettings['SPLITTING_MAX_DISTANCE']  = linking_max_distance
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
		    print(str(trackmate.getErrorMessage))
		    print("Moving on without processing...")
		else:
		       
			#----------------
			# Display results
			#----------------
			     
			selectionModel = SelectionModel(model)
			displayer =  HyperStackDisplayer(model, selectionModel, imp)
			displayer.render()
			displayer.refresh()

			if write_to_file:
				outFile = File(out_file)
				writer = TmXmlWriter(outFile)
				writer.appendModel(model)
				writer.appendSettings(settings)
				writer.writeToFile()
