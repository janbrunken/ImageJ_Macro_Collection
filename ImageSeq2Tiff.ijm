//ImageSeg2Tiff
//Version 0.1
//------------------------------------------------------------------
//ImageJ Macro to convert image sequences to single tiff files.
//By Jan Brunken
//------------------------------------------------------------------

input_path = getDirectory("input files");
fileList = getFileList(input_path);
xyCount = getBoolean("Do you want to process all XY points in the directory? (All should have the same dimensions.)");
if (xyCount == 1) {

	c_Count = getNumber("Enter the number of Channels", 1);
	z_Count = getNumber("Enter the number of Slices", 1);
	t_Count = getNumber("Enter the number of Frames", 1);
	for (f = 0; f < fileList.length; f++) {
		run("Image Sequence...", "open="+input_path+fileList[f]+" sort use");
		run("Stack to Hyperstack...", "order=xyczt(default) channels="+c_Count+" slices="+z_Count+" frames="+t_Count+" display=Color");
		saveAs("Tiff", input_path+"/"+fileList[f]+"XY"+f+1+".tif");
		run("Close All");
		
	}
}
else {
	xyToAnalyse = getNumber("Which point should be processed?XY:", 1);
	c_Count = getNumber("Enter the number of Channels", 1);
	z_Count = getNumber("Enter the number of Slices", 1);
	t_Count = getNumber("Enter the number of Frames", 1);
	run("Image Sequence...", "open="+input_path+fileList[xyToAnalyse-1]+" sort use");
		run("Stack to Hyperstack...", "order=xyczt(default) channels="+c_Count+" slices="+z_Count+" frames="+t_Count+" display=Color");
		saveAs("Tiff", input_path+"/"+fileList[xyToAnalyse-1]+"XY"+xyToAnalyse+".tif");
		run("Close All");
}