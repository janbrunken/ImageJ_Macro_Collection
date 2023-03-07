//ImageExporter
//Version 1.0
//------------------------------------------------------------------
//ImageJ macro for batch exporting of images.
//By Jan Brunken
//------------------------------------------------------------------

//Prepare for new export
start = getTime(); 
run("Close All");
run("Clear Results");	
print("\\Clear");
setOption("ExpandableArrays", true);
setBatchMode(true)
run("Bio-Formats Macro Extensions");
//Create dialogue 
rows = 4;
columns = 2;
labels = newArray("Process all series.", "Save channels as individual files (split channels).", "Save images as time series.", "Add scale bar.", "Apply median filter.", "Run auto-contrast correction.", "Export MaxIP.", "Export SumSP.");
defaults = newArray(false, false, false, false, false, false, false, false);
Dialog.create("Image Exporter 0.1");
Dialog.addMessage("The input directory has to contain image files that are readable by the Bioformats Importer plugin.\nNo other files should be contained.", 13, "#045FB4");
Dialog.addCheckboxGroup(rows,columns,labels,defaults);
Dialog.addNumber("Number of channels:", "1");
Dialog.addDirectory("Input directory", "/");
Dialog.addDirectory("Output directory", "/");
Dialog.show();
allSeries = Dialog.getCheckbox();
splitChan = Dialog.getCheckbox();
is4D = Dialog.getCheckbox();
scaleBar = Dialog.getCheckbox();
medFilter = Dialog.getCheckbox();
chCount = Dialog.getNumber();
autoContrast = Dialog.getCheckbox();
MaxIP = Dialog.getCheckbox();
SumSP = Dialog.getCheckbox();
//Get input paths and files
input_path = Dialog.getString();
fileList = getFileList(input_path);
output_path = Dialog.getString();
i = 0;
//Series Selection
if (allSeries == false){
	Dialog.createNonBlocking("Series Selection");
	Dialog.addNumber("Start series", 0);
	Dialog.addNumber("End series", 1);
	Dialog.show();
	startSeries = Dialog.getNumber();
	endSeries = Dialog.getNumber();
}
if (is4D == true) {
	items = newArray("tiff", "avi");
	Dialog.createNonBlocking("Save settings");
	Dialog.addChoice("Save as...", items);
	Dialog.show();
	saveFormat = Dialog.getChoice();
}
else {
	items = newArray("tiff", "png");
	Dialog.createNonBlocking("Save settings");
	Dialog.addChoice("Save as...", items);
	Dialog.show();
	saveFormat = Dialog.getChoice();
}
if (saveFormat == "avi") {
	items = newArray("none", "JPEG", "PNG");
	Dialog.createNonBlocking("Avi settings");
	Dialog.addChoice("Compression", items);
	Dialog.addNumber("Frames per second", 12);
	Dialog.show();
	compression = Dialog.getChoice();
	fps = Dialog.getNumber();
}
//Scale bar settings
if (scaleBar == true) {
	Dialog.createNonBlocking("Scale Bar Settings");
	Dialog.addNumber("Width", 50, 0, 2, "μm");
	Dialog.addNumber("Height", 8, 0, 2, "μm");
	Dialog.addNumber("Font", 28, 0, 2, "μm");
	Dialog.show();
	sbWidth = Dialog.getNumber();
	sbHeight = Dialog.getNumber();
	sbFont = Dialog.getNumber();
}
//Filter settings
if (medFilter == true) {
	Dialog.createNonBlocking("Median Filter Settings");
	Dialog.addNumber("Radius", 2.0, 1, 3, "px");
	Dialog.show();
	filterR = sbFont = Dialog.getNumber();
}

//Channel LUTs
Dialog.createNonBlocking("LUTs");
colors = newArray("Blue", "Cyan", "Grays", "Green", "Magenta", "Red", "Yellow", "-none-");
chColors = newArray(chCount);
for (c = 1; c <= chCount; c++) {
	Dialog.addChoice("C" + c, colors, colors[c-1]);
}
Dialog.show();
for (d = 1; d <= chCount; d++) {
	chColors[d-1] = Dialog.getChoice();
}
//Log window messages at start
print("---------------------");
print("ImageExporter v1.0");
print("---------------------");
//Remove folders from file list
length = fileList.length;
for (j = 0; j < length; j++) {
	if (indexOf(fileList[j-i] , "/") >= 0) {
		fileList = Array.deleteIndex(fileList, j-i);
		i++;
	}
	if (endsWith(fileList[j-i] , ".lifext")) {
		fileList = Array.deleteIndex(fileList, j-i);
		i++;
	}
}

print("The following list of files will be processed:");
Array.print(fileList); //Prints files that will be processed
if (fileList.length == 1) {
	print("-> 1 file in total");
}
else {
	print("-> " + fileList.length + " files in total");
}

//print("Export parameters:");

print("Now processing:");

for (f = 0; f < fileList.length; f++) {
	image = input_path + fileList[f]; //Current path and file name
	fileName = File.getNameWithoutExtension(image); //Current filename without extensions
	print(input_path + fileList[f] + " (file " + f+1 + " of " + fileList.length + ")"); //Displays file that is processed//Create output directory
	File.makeDirectory(output_path + fileName + "_exported"); //Make output directory
	export_path = output_path + fileName + "_exported"; //Current export path and file name without extension

	//Get series count
	if (allSeries == true) {
		Ext.setId(input_path + fileList[f]);
		Ext.getSeriesCount(seriesCount);
		startSeries = 1;
	}
	else {
		seriesCount = endSeries;
	}
	if (splitChan == 0) { //if no split channel export
		for (i = startSeries; i <= seriesCount; i++) {
			print("-> Series " + i + " of " + seriesCount);
			run("Bio-Formats Importer", "open=[" + image + "] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack series_" + i);
			if (MaxIP == true && SumSP == false) {
				File.makeDirectory(export_path + "/MaxIP");
				if (is4D == true) {
					run("Z Project...", "projection=[Max Intensity] all");
				}
				else {
					run("Z Project...", "projection=[Max Intensity]");
				}
				if (chCount == 1) {
					run(chColors[0]);
				}
				else {
					for (k = 0; k < chCount; k++) {
						Stack.setChannel(k+1);
						run(chColors[k]);
					}
				}
				if (scaleBar == true) { //if scale bar
					run("Scale Bar...", "width="  + sbWidth + " height=" + sbHeight + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
				}
				if (medFilter == true) { //if median filter
					run("Median...", "radius=" + filterR);
				}
				if (autoContrast == true) {
					run("Enhance Contrast", "saturated=0.35 process_all");
				}
				if (saveFormat == "avi") { //if avi export		
					run("AVI... ", "compression=" + compression + " frame=" + fps + " save=" + export_path + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.avi");
				}
				if (saveFormat == "png") { //if png export
					run("PNG...", "save=" + export_path + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.png");
				}
				if (saveFormat == "tiff") { //if tif export
					run("Tiff...", "save=" + export_path + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.tif");
				}
				run("Close All");
			}
			else if (MaxIP == false && SumSP == true) {
				File.makeDirectory(export_path + "/SumSP");
				if (is4D == true) {
					run("Z Project...", "projection=[Sum Slices] all");
				}
				else {
					run("Z Project...", "projection=[Sum Slices]");
				}
				if (chCount == 1) {
					run(chColors[0]);
				}
				else {
					for (k = 0; k < chCount; k++) {
						Stack.setChannel(k+1);
						run(chColors[k]);
					}
				}
				if (scaleBar == true) { //if scale bar
					run("Scale Bar...", "width="  + sbWidth + " height=" + sbHeight + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
				}
				if (medFilter == true) { //if median filter
					run("Median...", "radius=" + filterR);
				}
				if (autoContrast == true) {
					run("Enhance Contrast", "saturated=0.35 process_all");
				}
				if (saveFormat == "avi") { //if avi export		
					run("AVI... ", "compression=" + compression + " frame=" + fps + " save=" + export_path + "/SumSP/" + fileName + "_Series" + i + "_SumSP.avi");
				}
				if (saveFormat == "png") { //if png export
					run("PNG...", "save=" + export_path + "/SumSP/" + fileName + "_Series" + i + "_SumSP.png");
				}
				if (saveFormat == "tiff") { //if tif export
					run("Tiff...", "save=" + export_path + "/SumSP/" + fileName + "_Series" + i + "_SumSP.tif");
				}
				run("Close All");
			}
			else if (MaxIP == true && SumSP == true) {
				File.makeDirectory(export_path + "/MaxIP");
				if (is4D == true) {
					run("Z Project...", "projection=[Max Intensity] all");
				}
				else {
					run("Z Project...", "projection=[Max Intensity]");
				}
				if (chCount == 1) {
					run(chColors[0]);
				}
				else {
					for (k = 0; k < chCount; k++) {
						Stack.setChannel(k+1);
						run(chColors[k]);
					}
				}
				if (scaleBar == true) { //if scale bar
					run("Scale Bar...", "width="  + sbWidth + " height=" + sbHeight + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
				}
				if (medFilter == true) { //if median filter
					run("Median...", "radius=" + filterR);
				}
				if (autoContrast == true) {
					run("Enhance Contrast", "saturated=0.35 process_all");
				}
				if (saveFormat == "avi") { //if avi export		
					run("AVI... ", "compression=" + compression + " frame=" + fps + " save=" + export_path + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.avi");
				}
				if (saveFormat == "png") { //if png export
					run("PNG...", "save=" + export_path + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.png");
				}
				if (saveFormat == "tiff") { //if tif export
					run("Tiff...", "save=" + export_path + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.tif");
				}
				run("Close All");
				run("Bio-Formats Importer", "open=[" + image + "] color_mode=Composite rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack series_" + i);
				File.makeDirectory(export_path + "/SumSP");
				if (is4D == true) {
					run("Z Project...", "projection=[Sum Slices] all");
				}
				else {
					run("Z Project...", "projection=[Sum Slices]");
				}
				if (chCount == 1) {
					run(chColors[0]);
				}
				else {
					for (k = 0; k < chCount; k++) {
						Stack.setChannel(k+1);
						run(chColors[k]);
					}
				}
				if (scaleBar == true) { //if scale bar
					run("Scale Bar...", "width="  + sbWidth + " height=" + sbHeight + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
				}
				if (medFilter == true) { //if median filter
					run("Median...", "radius=" + filterR);
				}
				if (autoContrast == true) {
					run("Enhance Contrast", "saturated=0.35 process_all");
				}
				if (saveFormat == "avi") { //if avi export		
					run("AVI... ", "compression=" + compression + " frame=" + fps + " save=" + export_path + "/SumSP/" + fileName + "_Series" + i + "_SumSP.avi");
				}
				if (saveFormat == "png") { //if png export
					run("PNG...", "save=" + export_path + "/SumSP/" + fileName + "_Series" + i + "_SumSP.png");
				}
				if (saveFormat == "tiff") { //if tif export
					run("Tiff...", "save=" + export_path + "/SumSP/" + fileName + "_Series" + i + "_SumSP.tif");
				}
				run("Close All");
			}
			else {
				if (chCount == 1) {
					run(chColors[0]);
				}
				else {
					for (k = 0; k < chCount; k++) {
						Stack.setChannel(k+1);
						run(chColors[k]);
					}
				}
				if (scaleBar == true) { //if scale bar
					run("Scale Bar...", "width="  + sbWidth + " height=" + sbHeight + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
				}
				if (medFilter == true) { //if median filter
					run("Median...", "radius=" + filterR);
				}
				if (autoContrast == true) {
					run("Enhance Contrast", "saturated=0.35 process_all");
				}
				if (saveFormat == "avi") { //if avi export		
					run("AVI... ", "compression=" + compression + " frame=" + fps + " save=" + export_path + "/" + fileName + "_Series" + i + ".avi");
				}
				if (saveFormat == "png") { //if png export
					run("PNG...", "save=" + export_path + "/" + fileName + "_Series" + i + ".png");
				}
				if (saveFormat == "tiff") { //if tif export
					run("Tiff...", "save=" + export_path + "/" + fileName + "_Series" + i + ".tif");
				}
				run("Close All");
			}
		}
	}
	else { //if split channel export
		for (n = 0; n < chCount; n++) {
			if (chColors[n] == "-none-") {
				print("-");
			}
			else {
				File.makeDirectory(export_path + "/C" + n+1);
			}
		}
		for (i = startSeries; i <= seriesCount; i++) {
			print("-> Series " + i + " of " + seriesCount);
			run("Bio-Formats Importer", "open=[" + image + "] color_mode=Composite rois_import=[ROI manager] split_channels view=Hyperstack stack_order=XYCZT use_virtual_stack series_" + i);
			for (j = 0; j < chCount; j++) {
				if (chColors[chCount-j-1] == "-none-") {
					print("-");
					run("Close");
				}
				else {
					print("--> Channel " + j+1 + " of " + chCount);
					if (MaxIP == true && SumSP == false) {
						File.makeDirectory(export_path + "/C" + chCount - j + "/MaxIP");
						
						if (is4D == true) {
							run("Z Project...", "projection=[Max Intensity] all");
						}
						else {
							run("Z Project...", "projection=[Max Intensity]");
						}
						if (scaleBar == true) { //if scale bar
							run("Scale Bar...", "width="  + sbWidth + " height=" + sbHeight + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
						}
						if (medFilter == true) { //if median filter
							run("Median...", "radius=" + filterR);
						}
						if (autoContrast == true) {
							run("Enhance Contrast", "saturated=0.35 process_all");
						}
						if (saveFormat == "avi") { //if avi export		
							run("AVI... ", "compression=" + compression + " frame=" + fps + " save=" + "/C" + chCount-j + export_path + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.avi");
						}
						if (saveFormat == "png") { //if png export
							run("PNG...", "save=" + export_path + "/C" + chCount-j + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.png");
						}
						if (saveFormat == "tiff") { //if tif export
							run("Tiff...", "save=" + export_path + "/C" + chCount-j + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.tif");
						}
						run("Close");
						run("Close");
					}
					else if (MaxIP == false && SumSP == true) {
						File.makeDirectory(export_path + "/C" + j+1 + "/SumSP");
						if (is4D == true) {
							run("Z Project...", "projection=[Sum Slices] all");
						}
						else {
							run("Z Project...", "projection=[Sum Slices]");
						}
						if (chCount == 1) {
							run(chColors[0]);
						}
						else {
							for (k = 0; i < chCount; k++) {
								Stack.setChannel(k+1);
								run(chColors[k]);
							}
						}
						if (scaleBar == true) { //if scale bar
							run("Scale Bar...", "width="  + sbWidth + " height=" + sbHeight + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
						}
						if (medFilter == true) { //if median filter
							run("Median...", "radius=" + filterR);
						}
						if (autoContrast == true) {
							run("Enhance Contrast", "saturated=0.35 process_all");
						}
						if (saveFormat == "avi") { //if avi export		
							run("AVI... ", "compression=" + compression + " frame=" + fps + " save=" + export_path + "/C" + chCount-j + "/SumSP/" + fileName + "_Series" + i + "_SumSP.avi");
						}
						if (saveFormat == "png") { //if png export
							run("PNG...", "save=" + export_path + "/SumSP/" + "/C" + chCount-j + fileName + "_Series" + i + "_SumSP.png");
						}
						if (saveFormat == "tiff") { //if tif export
							run("Tiff...", "save=" + export_path + "/C" + chCount-j + "/SumSP/" + fileName + "_Series" + i + "_SumSP.tif");
						}
						run("Close");
						run("Close");
					}
					else if (MaxIP == true && SumSP == true) {
						File.makeDirectory(export_path + "/C" + chCount - j + "/MaxIP");
						if (is4D == true) {
							run("Z Project...", "projection=[Max Intensity] all");
						}
						else {
							run("Z Project...", "projection=[Max Intensity]");
						}
						
						if (scaleBar == true) { //if scale bar
							run("Scale Bar...", "width="  + sbWidth + " height=" + sbHeight + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
						}
						if (medFilter == true) { //if median filter
							run("Median...", "radius=" + filterR);
						}
						if (autoContrast == true) {
							run("Enhance Contrast", "saturated=0.35 process_all");
						}
						if (saveFormat == "avi") { //if avi export		
								run("AVI... ", "compression=" + compression + " frame=" + fps + " save=" + export_path + "/C" + chCount-j + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.avi");
						}
						if (saveFormat == "png") { //if png export
							run("PNG...", "save=" + export_path + "/C" + chCount-j + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.png");
						}
						if (saveFormat == "tiff") { //if tif export
							run("Tiff...", "save=" + export_path + "/C" + chCount-j + "/MaxIP/" + fileName + "_Series" + i + "_MaxIP.tif");
						}
						run("Close");
						File.makeDirectory(export_path + "/C" + chCount - j + "/SumSP");
						if (is4D == true) {
							run("Z Project...", "projection=[Sum Slices] all");
						}
						else {
							run("Z Project...", "projection=[Sum Slices]");
						}
						
						if (scaleBar == true) { //if scale bar
							run("Scale Bar...", "width="  + sbWidth + " height=" + sbHeight + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
						}
						if (medFilter == true) { //if median filter
							run("Median...", "radius=" + filterR);
						}
						if (autoContrast == true) {
							run("Enhance Contrast", "saturated=0.35 process_all");
						}
						if (saveFormat == "avi") { //if avi export		
							run("AVI... ", "compression=" + compression + " frame=" + fps + " save=" + export_path + "/C" + chCount-j + "/SumSP/" + fileName + "_Series" + i + "_SumSP.avi");
						}
						if (saveFormat == "png") { //if png export
							run("PNG...", "save=" + export_path + "/C" + chCount-j + "/SumSP/" + fileName + "_Series" + i + "_SumSP.png");
						}
						if (saveFormat == "tiff") { //if tif export
							run("Tiff...", "save=" + export_path + "/C" + chCount-j + "/SumSP/" + fileName + "_Series" + i + "_SumSP.tif");
						}
						run("Close");
						run("Close");
					}
					else {
						if (chCount == 1) {
							run(chColors[0]);
						}
						else {
							for (k = 0; k < chCount; k++) {
								Stack.setChannel(k+1);
								run(chColors[k]);
							}
						}
						if (scaleBar == true) { //if scale bar
							run("Scale Bar...", "width="  + sbWidth + " height=" + sbHeight + " font=" + sbFont + " color=White background=None location=[Lower Right] bold overlay");
						}
						if (medFilter == true) { //if median filter
							run("Median...", "radius=" + filterR);
						}
						if (autoContrast == true) {
							run("Enhance Contrast", "saturated=0.35 process_all");
						}
						if (saveFormat == "avi") { //if avi export		
							run("AVI... ", "compression=" + compression + " frame=" + fps + " save=" + export_path + "/C" + chCount-j + "/" + fileName + "_Series" + i + ".avi");
						}
						if (saveFormat == "png") { //if png export
							run("PNG...", "save=" + export_path + "/C" + chCount-j + "/" + fileName + "_Series" + i + ".png");
						}
						if (saveFormat == "tiff") { //if tif export
							run("Tiff...", "save=" + export_path + "/C" + chCount-j + "/" + fileName + "_Series" + i + ".tif");
						}
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
print("The ImageExporter took " + (getTime()-start)/60000 + " min to complete.");