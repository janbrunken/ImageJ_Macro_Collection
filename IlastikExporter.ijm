//Ilastik h5 Exporter
// Version 0.1
//------------------------------------------------------------------
//ImageJ Macro for exporting image files as .h5 for ilastik training.
//By Jan Brunken
//------------------------------------------------------------------

//Prepare for new export
run("Close All");
run("Clear Results");	
print("\\Clear");
setOption("ExpandableArrays", true);
setBatchMode(true)
run("Bio-Formats Macro Extensions");
Dialog.createNonBlocking("Ilastik h5 Exporter 0.1")
Dialog.addMessage("Don't specify any values with space characters (file names, directories).\nThe input directory has to contain image files that are readable by the Bioformats Importer plugin and no other files should be contained.", 15, "#045FB4");
Dialog.addCheckbox("Export as maximum intensity projection (2D sementation).", false);
Dialog.addCheckbox("Save channels as individual files (split channels).", false);
Dialog.addCheckbox("Process last series (stiched tiles).", false);
Dialog.addDirectory("Input directory", "/");
Dialog.addDirectory("Output directory", "/");
Dialog.show();
maxChoice = Dialog.getCheckbox();
splitChan = Dialog.getCheckbox();
stTiles = Dialog.getCheckbox();
//Get input paths and files
input_path = Dialog.getString();
fileList = getFileList(input_path);
output_path = Dialog.getString();


print("---------------------");
print("Ilastik h5 Exporter v1.0");
print("---------------------");

length = fileList.length;
i = 0;
for (j = 0; j < length; j++) {
	if (indexOf(fileList[j-i] , "/") >= 0) {
		fileList = Array.deleteIndex(fileList, j-i);
		i++;
	}
}
print("The following list of files will be processed:");
Array.print(fileList); //Prints files that will be processed
print("-> " + fileList.length + " files in total");
print("Now processing:");
for (f = 0; f < fileList.length; f++) {

	image = input_path + fileList[f]; //Current path and file name
	fileName = File.getNameWithoutExtension(image); //Current filename without extensions
	print(input_path + fileList[f] + " (file " + f+1 + " of " + fileList.length + ")"); //Displays file that is processed

	if (maxChoice == true) {

		//Create output directory
		File.makeDirectory(output_path + fileName + "_2D"); //Make output directory
		export_path = output_path + fileName + "_2D"; //Current export path and file name without extension
	}

	else {
		//Create output directory
		File.makeDirectory(output_path + fileName + "_3D"); //Make output directory
		export_path = output_path + fileName + "_3D"; //Current export path and file name without extension
	}
	//Get series count
	Ext.setId(input_path + fileList[f]);
	Ext.getSeriesCount(seriesCount);

	//Open and export image
	if (maxChoice == 0) { //If no MaxIP export
		if (splitChan == 0) {  //If no split channel export
			if (stTiles == 0) { //If stiched tiles not exported
				for (i = 1; i < seriesCount; i++) {
					print("-> Series " + i + " of " + seriesCount);
					run("Bio-Formats Importer", "open=[" + image + "] color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + i);
					exportArgs = "select=" + export_path + "/"+ fileName + "_Series" + i + ".h5 datasetname=data compressionlevel=0";
					run("Export HDF5", exportArgs);
					run("Close All");
				}
			}
			else { //If stiched tiles exported
				for (i = 1; i <= seriesCount; i++) {
					print("-> Series " + i + " of " + seriesCount);
					run("Bio-Formats Importer", "open=[" + image + "] color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + i);
					exportArgs = "select=" + export_path + "/"+ fileName + "_Series" + i + ".h5 datasetname=data compressionlevel=0";
					run("Export HDF5", exportArgs);
					run("Close All");
				}
			}
		}
		else { //If split channel export
			if (stTiles == 0) { //If stiched tiles not exported
				for (i = 1; i < seriesCount; i++) {
					print("-> Series " + i + " of " + seriesCount);
					run("Bio-Formats Importer", "open=[" + image + "] color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + i);
					getDimensions(width, height, channels, slices, frames);
					if (i == 1) {
						for (n = 0; n < channels; n++) {
						File.makeDirectory(export_path + "/C" + n+1);
						}
					}
					run("Split Channels");
					for (j = 0; j < channels; j++) {
						print("--> Channel " + j+1 + " of " + channels);
						exportArgs = "select=" + export_path + "/C"+ channels-j + "/" + fileName + "_Series" + i + "_C" + channels-j + ".h5 datasetname=data compressionlevel=0";
						run("Export HDF5", exportArgs);
						run("Close");
					}
				}
			}
			else{ //If stiched tiles exported
				for (i = 1; i <= seriesCount; i++) {
					print("-> Series " + i + " of " + seriesCount);
					run("Bio-Formats Importer", "open=[" + image + "] color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + i);
					getDimensions(width, height, channels, slices, frames);
					if (i == 1) {
						for (n = 0; n < channels; n++) {
						File.makeDirectory(export_path + "/C" + n+1);
						}
					}
					run("Split Channels");
					for (j = 0; j < channels; j++) {
						print("--> Channel " + j+1 + " of " + channels);
						exportArgs = "select=" + export_path + "/C"+ channels-j + "/" + fileName + "_Series" + i + "_C" + channels-j + ".h5 datasetname=data compressionlevel=0";
						run("Export HDF5", exportArgs);
						run("Close");
					}
				}
			}
		}
	}
	else { //If MaxIP export
		if (splitChan == 0) { //If no split channel export
			if (stTiles == 0) { //If stiched tiles not exported
				for (i = 1; i < seriesCount; i++) {
				print("-> Series " + i + " of " + seriesCount);
				run("Bio-Formats Importer", "open=[" + image + "] color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + i);
				run("Z Project...", "projection=[Max Intensity]");
				exportArgs = "select=" + export_path + "/"+ fileName + "_Series" + i + ".h5 datasetname=data compressionlevel=0";
				run("Export HDF5", exportArgs);
				run("Close All");
				}
			}
			else { // If stiched tiles exported
				for (i = 1; i <= seriesCount; i++) {
				print("-> Series " + i + " of " + seriesCount);
				run("Bio-Formats Importer", "open=[" + image + "] color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + i);
				run("Z Project...", "projection=[Max Intensity]");
				exportArgs = "select=" + export_path + "/"+ fileName + "_Series" + i + ".h5 datasetname=data compressionlevel=0";
				run("Export HDF5", exportArgs);
				run("Close All");
				}
			}
		}
		else { //If split channel export
			if (stTiles == 0) {//If stiched tiles not exported
				for (i = 1; i < seriesCount; i++) {
					print("-> Series " + i + " of " + seriesCount);
					run("Bio-Formats Importer", "open=[" + image + "] color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + i);
					getDimensions(width, height, channels, slices, frames);
					if (i == 1) {
						for (n = 0; n < channels; n++) {
						File.makeDirectory(export_path + "/C" + n+1);
						}
					}
					run("Split Channels");
					for (j = 0; j < channels; j++) {
						print("--> Channel " + j+1 + " of " + channels);
						run("Z Project...", "projection=[Max Intensity]");
						exportArgs = "select=" + export_path + "/C"+ channels-j + "/" + fileName + "_Series" + i + "_C" + channels-j + ".h5 datasetname=data compressionlevel=0";
						run("Export HDF5", exportArgs);
						run("Close");
						run("Close");
					}
				}
			}
			else { //If stiched tiles exported
				for (i = 1; i <= seriesCount; i++) {
					print("-> Series " + i + " of " + seriesCount);
					run("Bio-Formats Importer", "open=[" + image + "] color_mode=Grayscale rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_" + i);
					getDimensions(width, height, channels, slices, frames);
					if (i == 1) {
						for (n = 0; n < channels; n++) {
						File.makeDirectory(export_path + "/C" + n+1);
						}
					}
					run("Split Channels");
					for (j = 0; j < channels; j++) {
						print("--> Channel " + j+1 + " of " + channels);
						run("Z Project...", "projection=[Max Intensity]");
						exportArgs = "select=" + export_path + "/C"+ channels-j + "/" + fileName + "_Series" + i + "_C" + channels-j + ".h5 datasetname=data compressionlevel=0";
						run("Export HDF5", exportArgs);
						run("Close");
						run("Close");
					}
				}	
			}
		}
	}
}

print("---------------------");
print("Done.");

//Prepare for new image
run("Clear Results");