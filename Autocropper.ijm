//Autocropper
//Version 0.1
//------------------------------------------------------------------
//ImageJ Macro for cropping images into RxC (Row x Columns) tiles.
//By Jan Brunken
//------------------------------------------------------------------

start = getTime(); 
setBatchMode(true)
run("Close All");
Dialog.create("Title");
Dialog.addMessage("This macro chops an image into RxC (Rows x Columns) tiles.");
Dialog.createNonBlocking("Autocropper 0.1");
Dialog.addMessage("1. Select input & output directories:", 13, "#045FB4");
Dialog.addDirectory("Input directory for MaxIPs", "/");
Dialog.addDirectory("Output directory", "/");
Dialog.addMessage("2. Select the cropping dimensions (Columns x Rows):", 13, "#045FB4");
Dialog.addNumber("C=", 5);
Dialog.addNumber("R=", 4);
Dialog.show();
max_input_path = Dialog.getString();
output_path = Dialog.getString();
max_fileList = getFileList(max_input_path);
m=Dialog.getNumber();
n=Dialog.getNumber();
File.makeDirectory(output_path + "/cropped");

print("---------------------");
print("Autocropper v1.0");
print("---------------------");

//Remove folders from file list
length = max_fileList.length;
i=0
for (j = 0; j < length; j++) {
	if (indexOf(max_fileList[j-i] , "/") >= 0) {
		fileList = Array.deleteIndex(max_fileList, j-i);
		i++;
	}
}

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
	for (y = 0; y < n; y++) { 
		offsetY = y * height / n; 
 		for (x = 0; x < m; x++) { 
			offsetX = x * width / m; 
			selectImage(id); 
 			call("ij.gui.ImageWindow.setNextLocation", locX + offsetX, locY + offsetY); 
			tileTitle = title + " [" + x + "," + y + "]"; 
 			run("Duplicate...", "title=" + tileTitle); 
			makeRectangle(offsetX, offsetY, tileWidth, tileHeight); 
 			run("Crop");
 			run("Tiff...", "save=" + output_path + "cropped/" + max_fileName + "_tile_" + y + "_" + x + ".tif");
			close();
		} 
	}
	selectImage(id); 
	close();
}
print("Done.");
print("The Autocropper took " + (getTime()-start)/60000 + " min to complete."); 
