run("Close All");
roiManager("reset");



folder = "C:\\Users\\SaraSantos\\Desktop\\Ovaries quantification\\";
open(folder + "SaraS_027.tiff");
run("8-bit");
title = getTitle();
run("Duplicate...", "title=Duplicated");
selectWindow("Duplicated");

run("Set Scale...", "distance=0 known=0 unit=pixel");

run("Subtract Background...", "rolling=1000 sliding");


binarize_ovaries();

binary_to_entities();


draw_correcting_areas();

run("Clear Results");

export_total_area_value();



/////// Functions///////////////////////////


function binarize_ovaries(){
    run("Median...", "radius=2");
    setAutoThreshold("Huang dark");
    //setThreshold(30, 255);
    setOption("BlackBackground", true);
    run("Convert to Mask"); //creates ROI
    run("Fill Holes"); // fills holes inside ROIs
    run("Watershed"); //separates ovaries from other areas
}


// Convert binarized ovaries into ROIs
function binary_to_entities(){
	
	// Retrieve the ovaries' boundaries
	run("Set Measurements...", "area mean centroid redirect=None decimal=0");
	run("Analyze Particles...", "size=20000-1000000 circularity=0.00-1.00 display add");

	
	roiManager("Show All");
	selectWindow(title);
	setForegroundColor(0, 0, 0); // Set the foreground color to red
	roiManager("Draw");
	roiManager("Sort"); // Sort ROIs by size
	//delete ROIs smaller than ovaries (3rd roi and below):
	while (roiManager("count") > 2) {
 		roi_length = roiManager("count");
 		roiManager("select", roi_length-1);
		roiManager("delete"); // delete those ROIs and leave the 2 biggest ones
	}
}
	
//function for the user to draw missing parts
   
function draw_correcting_areas() {
	//(need to add option to not draw areas if not needed)
	
	//add missing areas
	setTool("freehand");
    waitForUser("Draw first missing area to add", "Draw area, then click OK. /n If no area to add, draw inside an ovary.");
    roiManager("Add");
    setTool("freehand");
    waitForUser("Draw second missing area to add", "Use the ROI tools to draw any missing areas, then click OK.");
    roiManager("Add");
    roiManager("deselect"); //deselect all ROIs to make sure they re all merged together later
    roiManager("Combine");
    roiManager("Add"); //merge in position 4
    
    //draw areas to delete
    setTool("freehand");
    waitForUser("Draw first area to delete", "Draw area, then click OK.");
    roiManager("Add"); //position 5
    setTool("freehand");
    waitForUser("Draw second area to delete", "Draw area, then click OK.");
    roiManager("Add"); //position 6
    //select newly drawn areas and merge them
    roiManager("Select", 5);
	roiManager("Select", newArray(5,6));
    roiManager("Combine");
    roiManager("Add"); //merge in position 7
    
    //XOR (common pixels are deleted) new drawn merged area (position 5) from the original big area (position 2)
    roiManager("Select", 4);
    roiManager("Select", newArray(4,7));
    roiManager("XOR");
    roiManager("Add"); //XOR to position 8
    
    //AND (only common pixels are kept) fow new area in 8 with original ovaries selection in 4
    roiManager("Select", 4);
    roiManager("Select", newArray(4,8));
    roiManager("AND");
    roiManager("Add"); //AND to position 9
}



//Function to export areas to new or existing Array
	

function export_total_area_value(){
	length = roiManager("count");
	roiManager("select", length-1); //select last final area to quantify
	roiManager("Measure"); //get Area to Results table 
	setResult("file", nResults-1, title); //add image file name to column
	//use the area of ovaries from Results and divide by the number of pixels of 1 mm2
	//ATT: optimized by Sara in her specific conditions
	pixels_per_mm2 = 270150; //pixels/mm2
	area_mm2 = getResult("Area", nResults-1)/pixels_per_mm2; //calculate area of ovaries in mm2
	
	setResult("area_mm2", nResults-1 , area_mm2); //add to Results; ADDING WITHOUT DECIMAL PLACES
	print(area_mm2); //temporary workaround to get area with decimal places
	run("Flatten"); //new image to save with final area drawn
	saveAs("Tiff", "C:/Users/SaraSantos/Desktop/Ovaries quantification/"+ title + "with areas" + ".tiff"); // save image with areas selected
}

