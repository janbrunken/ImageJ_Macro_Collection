
//Canny edge batch processor
//Version 0.1
//------------------------------------------------------------------
//ImageJ Macro for segmenting images using a Canny edge algorithm.
//By Jan Brunken
//------------------------------------------------------------------

start = getTime(); 
setBatchMode(true)
run("Close All");
Dialog.create("Title");
Dialog.addMessage("This macro chops an image into RxC (Rows x Columns) tiles.");
Dialog.createNonBlocking("Canny Edge Batch Processor 0.1");
Dialog.addMessage("1. Select input & output directories:", 13, "#045FB4");
Dialog.addDirectory("Input directory", "/");
Dialog.addDirectory("Output directory", "/");
Dialog.addMessage("2. Select Canny edge detection parameters:", 13, "#045FB4");
Dialog.addNumber("Gaussian kernel radius=", 2);
Dialog.addNumber("Low threshold=", 2.5);
Dialog.addNumber("High threshold=", 7.5);
Dialog.addCheckbox("Normalize contrast", false);
Dialog.addMessage("3. Select addtional filter parameters:", 13, "#045FB4");
Dialog.addNumber("Maximum kernel radius=", 1.25);
Dialog.addNumber("Close kernel iterations=", 8);
Dialog.addNumber("Close kernel count=", 4);
Dialog.addNumber("Open kernel iterations=", 10);
Dialog.addNumber("Open kernel count=", 3);
Dialog.addNumber("Erode kernel iterations=", 2);
Dialog.addNumber("Erode kernel count=", 4);
Dialog.addCheckbox("Time lapse data", false);
Dialog.show();
input_path = Dialog.getString();
output_path = Dialog.getString();
fileList = getFileList(input_path);
gkr=Dialog.getNumber();
lt=Dialog.getNumber();
ht=Dialog.getNumber();
nc = Dialog.getCheckbox();
max_kr=Dialog.getNumber();
close_it=Dialog.getNumber();
close_count=Dialog.getNumber();
open_it=Dialog.getNumber();
open_count=Dialog.getNumber();
erode_it=Dialog.getNumber();
erode_count=Dialog.getNumber();
tl = Dialog.getCheckbox();
File.makeDirectory(output_path + "/masks");

print("---------------------");
print("Canny edge batch processor v1.0");
print("---------------------");

//Remove folders from file list
length = fileList.length;
i=0
for (j = 0; j < length; j++) {
	if (indexOf(fileList[j-i] , "/") >= 0) {
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
print("Now processing:");
if (tl==true) {
	for (f = 0; f < fileList.length; f++) {
		File.makeDirectory(output_path + "/temp");
		image = input_path + fileList[f]; //Current path and file name
		fileName = File.getNameWithoutExtension(fileList[f]); //Current filename without extensions
		print("-> Processing series " + f+1 + " of " + fileList.length + ":");
		print("--> " + image + " (file " + f+1 + " of " + fileList.length + ")"); //Displays file that is processed
		open(image);
		getDimensions(width, height, channels, slices, frames);;
		run("Stack to Images");
		for (i = 0; i < frames; i++) {
			if (nc==false) {
				run("Canny Edge Detector", "gaussian=" + gkr + " low=" + lt + " high=" + ht);
			}
			else {
				run("Canny Edge Detector", "gaussian=" + gkr + " low=" + lt + " high=" + ht + " normalize");
			}
			saveAs("Tiff", output_path + "/temp/" + i + ".tif");
			close();
		}
		open(output_path + "/temp/0.tif");
		open(output_path + "/temp/1.tif");
		run("Concatenate...", "  title=current open image1=0.tif image2=1.tif image3=[-- None --]");
		for (i = 2; i < frames; i++) {
			open(output_path + "/temp/" + i + ".tif");
			run("Concatenate...", "  title=current open image1=current image2=" + i + ".tif image3=[-- None --]");
		}
		run("Maximum...", "radius=" + max_kr + " stack");
		run("Options...", "iterations=" + close_it + " count=" + close_count + " pad do=Close stack");
		run("Options...", "iterations=" + open_it + " count=" + open_count + " do=Open stack");
		run("Options...", "iterations=" + erode_it + " count=" + erode_count + " do=Erode stack");
		run("Tiff...", "save=" + output_path + "masks/" + fileName + "_mask.tif");
		close();
		for (i = 0; i < frames; i++) {
			File.delete(output_path + "/temp/" + i + ".tif");
		}
		File.delete(output_path + "/temp");
	}
}
else {
	
	for (f = 0; f < fileList.length; f++) {
		image = input_path + fileList[f]; //Current path and file name
		fileName = File.getNameWithoutExtension(fileList[f]); //Current filename without extensions
		print("-> Processing series " + f+1 + " of " + fileList.length + ":");
		print("--> " + image + " (file " + f+1 + " of " + fileList.length + ")"); //Displays file that is processed
		open(image);
		if (nc==false) {
			run("Canny Edge Detector", "gaussian=" + gkr + " low=" + lt + " high=" + ht);
		}
		else {
			run("Canny Edge Detector", "gaussian=" + gkr + " low=" + lt + " high=" + ht + " normalize");
		}

		run("Maximum...", "radius=" + max_kr + " stack");
		run("Options...", "iterations=" + close_it + " count=" + close_count + " pad do=Close stack");
		run("Options...", "iterations=" + open_it + " count=" + open_count + " do=Open stack");
		run("Options...", "iterations=" + erode_it + " count=" + erode_count + " do=Erode stack");
		run("Tiff...", "save=" + output_path + "masks/" + fileName + "_mask.tif");
		close();
	}
}
print("Done.");
print("The Canny edge batch processor took " + (getTime()-start)/60000 + " min to complete."); 