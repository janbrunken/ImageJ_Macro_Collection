//StarDistBatchProcessor
//Version 0.1
//------------------------------------------------------------------
//ImageJ Macro to apply pre-trained StarDist2D versatile fluorescence model to a set of images
//By Jan Brunken
//------------------------------------------------------------------
start = getTime(); 
//setBatchMode(true)
run("Close All");
run("Clear Results");
roiManager("reset");
Dialog.createNonBlocking("StarDist2D Batch Processor 0.1");
Dialog.addMessage("1. Select input & output directories:", 13, "#045FB4");
Dialog.addDirectory("Input directory for MaxIPs", "/");
Dialog.addDirectory("Output directory", "/");
Dialog.addMessage("2. Select the cropping dimensions (Columns x Rows):", 13, "#045FB4");
Dialog.addNumber("C=", 5);
Dialog.addNumber("R=", 4);
Dialog.addMessage("3. Select the scaling factor:", 13, "#045FB4");
Dialog.addNumber("s=", 0.25);
Dialog.addMessage("4. Select StarDist Parameters:", 13, "#045FB4");
Dialog.addSlider("Percentile low=" 0.0, 100.0, 1.0);
Dialog.addSlider("Percentile high=" 0.0, 100.0, 99.8);
Dialog.addSlider("Probability threshold=" 0.00, 1.00, 0.50);
Dialog.addSlider("Overlap threshold=" 0.00, 1.00, 0.40);
Dialog.show();
max_input_path = Dialog.getString();
output_path = Dialog.getString();
max_fileList = getFileList(max_input_path);
m=Dialog.getNumber();
n=Dialog.getNumber();
sf=Dialog.getNumber();
pb = Dialog.getNumber();
pt = Dialog.getNumber();
prt = Dialog.getNumber();
nmst = Dialog.getNumber();
File.makeDirectory(output_path + "/Labels"); //Make labels output directory
File.makeDirectory(output_path + "/ROIs"); //Make ROIs output directory
File.makeDirectory(output_path + "/StarDist_Measurements"); //Make labels output directory
File.makeDirectory(output_path + "/MaxIP_Tiles"); //Make tiles output directory

print("---------------------");
print("StarDist2D Batch Processor v1.0");
print("---------------------");

print("The following list of files will be processed:");
Array.print(max_fileList); //Prints files that will be processed
if (max_fileList.length == 1) {
	print("-> 1 file in total");
}
else {
	print("-> " + max_fileList.length + " files in total");
}
print("-> " + m*n + " tiles will be processed");
print("Now processing:");
for (f = 0; f < max_fileList.length; f++) {
	max_image = max_input_path + max_fileList[f]; //Current path and file name
	max_fileName = File.getNameWithoutExtension(max_fileList[f]); //Current filename without extensions
	print("-> Processing series " + f+1 + " of " + max_fileList.length + ":");
	print("--> " + max_image + " (file " + f+1 + " of " + max_fileList.length + ")"); //Displays file that is processed
	open(max_image);
	id = getImageID(); 
	title = getTitle(); 
	getLocationAndSize(locX, locY, sizeW, sizeH); 
	width = getWidth(); 
	height = getHeight();
	tileWidth = width / m; 
	tileHeight = height / n;
	scaled_width = tileWidth * sf;
	scaled_height = tileHeight * sf;
	for (y = 0; y < n; y++) { 
		offsetY = y * height / n; 
 		for (x = 0; x < m; x++) { 
 			print("--> Processing tile " + y*m+x+1 + " of " + m*n + ":");
			offsetX = x * width / m; 
			selectImage(File.getName(max_fileList[f])); 
 			call("ij.gui.ImageWindow.setNextLocation", locX + offsetX, locY + offsetY); 
			tileTitle = title + " [" + x + "," + y + "]"; 
 			run("Duplicate...", "title=" + tileTitle); 
			makeRectangle(offsetX, offsetY, tileWidth, tileHeight); 
 			run("Crop");
 			run("Size...", "width=" + scaled_width + " height=" + scaled_height + " depth=1 constrain average interpolation=Bilinear");
 			run("Tiff...", "save=" + output_path + "MaxIP_Tiles" + "/" + max_fileName + "_tile_" + y + "_" + x + ".tif");
 			current_tile = output_path + "MaxIP_Tiles" + "/" + max_fileName + "_tile_" + y + "_" + x + ".tif";
 			close();
 			open(current_tile);
			tile_title = getTitle();
			print("---> StarDist...");
 			run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'" + tile_title + "', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'" + pb + "', 'percentileTop':'" + pt + "', 'probThresh':'" + prt + "', 'nmsThresh':'" + nmst + "', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
			print("---> Saving label mask...");
			run("Duplicate...", " ");
			print("---> Saving tile image...");
			run("Tiff...", "save=" + output_path + "Labels" + "/" + max_fileName + "_Labels_tile_" + y + "_" + x + ".tif");
			if (roiManager("count") == 0) {
				print("<--> Tile " + y + "_" + x + "skipped. No nuceuls detected.");
				print("---> Preparing for next series...");
				close();
				close();
				close();
				//run("Clear Results");
				roiManager("reset");
			}
			else {
				print("---> Saving ROIs...");
				roiManager("Save", output_path + "/ROIs/" + max_fileName + "_ROIset_tile_" + y + "_" + x + ".zip");
				roiManager("Measure");
				//print("---> Saving results...");
				//saveAs("Results", output_path + "/StarDist_Measurements/" + max_fileName + "_Results_tile_" + y + "_" + x + ".csv");
				print("---> Preparing for next series...");
				//run("Clear Results");
				roiManager("reset");
				close();
				close();
				close();
			}
		}
	}
	run("Close All");
	print("---> Saving results...");
	saveAs("Results", output_path + "/StarDist_Measurements/" + max_fileName + "_Results_tile_.csv");
	run("Clear Results");
}
print("Done.");
print("The StarDist batch Processor took " + (getTime()-start)/60000 + " min to complete.");