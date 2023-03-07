//StarDist2DMeasurementBatchProcessor
//Version 0.1
//------------------------------------------------------------------
//ImageJ Macro to apply pre-trained StarDist2D versatile fluorescence model to a set of images and return measured features as csv file.
//By Jan Brunken
//------------------------------------------------------------------
start = getTime(); 
//setBatchMode(true)
run("Close All");
run("Clear Results");
roiManager("reset");
Dialog.createNonBlocking("StarDist2D Measurement Batch Processor 0.1")
Dialog.addDirectory("Input directory for MaxIPs", "/");
Dialog.addDirectory("Input directory for SumSPs", "/");
Dialog.addDirectory("Output directory", "/");
Dialog.show();
max_input_path = Dialog.getString();
sum_input_path = Dialog.getString();
output_path = Dialog.getString();
max_fileList = getFileList(max_input_path);
sum_fileList = getFileList(sum_input_path);
//Make output directories
File.makeDirectory(output_path + "/Labels"); //Make labels output directory
File.makeDirectory(output_path + "/ROIs"); //Make ROIs output directory
File.makeDirectory(output_path + "/ROIs/TouchingEdges"); //Make edge touching ROIs output directory
File.makeDirectory(output_path + "/ROIs/NoTouchingEdges"); //Make no edgge touching ROIs output directory
File.makeDirectory(output_path + "/StarDist_Measurements"); //Make labels output directory

print("---------------------");
print("StarDist 2D Measurement BatchProcessor v1.0");
print("---------------------");

print("The following list of files will be processed:");
Array.print(max_fileList); //Prints files that will be processed
if (max_fileList.length == 1) {
	print("-> 1 file in total");
}
else {
	print("-> " + max_fileList.length + " files in total");
}
print("Now processing:");
for (f = 0; f < max_fileList.length; f++) {
	max_image = max_input_path + max_fileList[f]; //Current path and file name
	sum_image = sum_input_path + sum_fileList[f]; //Current path and file name
	max_fileName = File.getNameWithoutExtension(max_fileList[f]); //Current filename without extensions
	print("-> Processing series " + f+1 + " of " + max_fileList.length + ":");
	print("--> " + max_image + " (file " + f+1 + " of " + max_fileList.length + ")"); //Displays file that is processed//Create output directory
	print("---> Loading MaxIP image...");
	open(max_image);
	print("---> StarDist...");
	run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + max_fileList[f] + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.6500000000000001', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
	if (roiManager("count") == 0) {
	print("<---> Series " + f+1 + "skipped. No nuceuls detected.<--->");
	print("---> Preparing for next series...");
			run("Close All");
			run("Clear Results");
			roiManager("reset");
	}
	else {
		print("---> Saving TouchingROIs...");
		roiManager("Save", output_path + "/ROIs/TouchingEdges/" + max_fileName + "_Touching_ROIset.zip");
		roiManager("reset");
		print("---> Setting threshold...");
		setThreshold(0, 0);
		print("---> Converting to binary mask...");
		run("Convert to Mask");
		run("Invert");
		print("---> Watershed segmentation...");
		run("Watershed");
		print("---> Analyzing particles...");
		//run("Analyze Particles...", "size=400-2500 circularity=0.70-1.00 display exclude clear add");
		run("Analyze Particles...", "circularity=0.70-1.00 display exclude clear add");
		nROIs= roiManager("count");
		for (i = 0; i < nROIs; i++) {
			roiManager("Select", i);
			run("Enlarge...", "enlarge=1 pixel");
			roiManager("Update");
		}
		roiManager("Deselect");
		print("---> Removing edge touching nuclei...");
		selectWindow(max_fileList[f]);
		roiManager("Combine");
		run("Clear Outside");
		roiManager("reset");
		print("---> StarDist...");
		run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + max_fileList[f] + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.6500000000000001', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
		if (roiManager("count") == 0) {
			print("<--> Series " + f+1 + "skipped. No nuceuls detected.");
			print("---> Preparing for next series...");
			run("Close All");
			run("Clear Results");
			roiManager("reset");
		}
		else {
			print("---> Saving NoTouchingROIs...");
			roiManager("Save", output_path + "/ROIs/NoTouchingEdges/" + max_fileName + "_NoTouching_ROIset.zip");
			roiManager("reset");
			print("---> Saving label mask...");
			saveAs("Tiff", output_path + "/Labels/" + max_fileName + "_Labels.tif");
			run("Close All");
			run("Clear Results");
			print("---> Loading SumSP image...");
			open(sum_image);
			print("---> Loading TouchingROIs...");
			open(output_path + "/ROIs/TouchingEdges/" + max_fileName + "_Touching_ROIset.zip");
			print("---> Measuring background...");
			roiManager("Combine");
			run("Make Inverse");
			run("Measure");
			roiManager("reset");
			print("---> Loading NoTouchingROIs...");
			open(output_path + "/ROIs/NoTouchingEdges/" + max_fileName + "_NoTouching_ROIset.zip");	
			print("---> Measuring nuclei properties...");
			roiManager("Measure");
			print("---> Saving results...");
			saveAs("Results", output_path + "/StarDist_Measurements/" + max_fileName + "Results.csv");
			print("---> Preparing for next series...");
			run("Close All");
			run("Clear Results");
			roiManager("reset");
		}
	}
}
print("Done.");
print("The StarDist batch Processor took " + (getTime()-start)/60000 + " min to complete.");