// import external libraries
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.core.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.events.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.interactions.*;
import de.fhpotsdam.unfolding.mapdisplay.*;
import de.fhpotsdam.unfolding.mapdisplay.shaders.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.texture.*;
import de.fhpotsdam.unfolding.tiles.*;
import de.fhpotsdam.unfolding.ui.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.utils.*;
import java.util.Date;
import java.text.SimpleDateFormat;

String allTripsFile = "../data/portland_20170414.csv";

String dataFile = allTripsFile;

int totalFrames = 3600;
int totalSeconds;

UnfoldingMap map;

Table tripTable;
ArrayList<Trips> trips = new ArrayList<Trips>();
ArrayList<Integer> types = new ArrayList<Integer>();

ScreenPosition startPos;
ScreenPosition endPos;
Location startLocation;
Location endLocation;

PFont f;
int cab_type;
PImage img;

// date variables For parsing dates
Date minDate;
Date maxDate;
Date startDate;
Date endDate;
Date thisStartDate;
Date thisEndDate;

AbstractMapProvider provider1;
AbstractMapProvider provider2;
AbstractMapProvider provider3;
AbstractMapProvider provider4;
AbstractMapProvider provider5;
AbstractMapProvider provider6;
AbstractMapProvider provider7;
AbstractMapProvider provider8;
AbstractMapProvider provider9;
AbstractMapProvider provider0;

void setup() {
  //size(1000, 860, P2D);
  fullScreen(P2D);
  smooth();
  loadData();
  println("Finished loading data");
  
  // Choose map provider
  
  provider1 = new OpenStreetMap.OpenStreetMapProvider();
  provider2 = new StamenMapProvider.TonerBackground();
  provider3 = new Microsoft.AerialProvider();
  provider4 = new Microsoft.RoadProvider();
  provider5 = new Yahoo.RoadProvider();
  provider6 = new Yahoo.HybridProvider();
  provider7 = new AcetateProvider.Hillshading();
  provider8 = new Google.GoogleTerrainProvider();
  provider9 = new Google.GoogleMapProvider();

  
  map = new UnfoldingMap(this); // default
  
  MapUtils.createDefaultEventDispatcher(this, map);
  
  //map = new UnfoldingMap(this, new Microsoft.AerialProvider());
  //map = new UnfoldingMap(this, new StamenMapProvider.TonerBackground());
  
  
  // Center map on Portland
  Location portland = new Location(45.522094, -122.6746037);
  int zoom = 11;
  map.zoomAndPanTo(zoom, portland);
  MapUtils.createDefaultEventDispatcher(this, map);
  
}

void loadData() {
  Table tripTable = loadTable(dataFile, "header");
  println(str(tripTable.getRowCount()) + " records loaded...");
  
  // define date format of raw data
  SimpleDateFormat myDateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
  
  // calculate min and max start times (must be sorted ascending)
  String first = tripTable.getString(0, "starttime");
  String last = tripTable.getString(tripTable.getRowCount()-1, "stoptime");
  
  //println(first);
  
  try {
    minDate = myDateFormat.parse(first);
    maxDate = myDateFormat.parse(last);
    totalSeconds = int(maxDate.getTime()/1000) - int(minDate.getTime()/1000);
    //totalSeconds = totalSeconds/2;
  } 
  catch (Exception e) {
    println("Unable to parse date stamp");
  }
  println("Min starttime:", minDate, ". In epoch:", minDate.getTime()/1000);
  println("Max starttime:", maxDate, ". In seconds:", maxDate.getTime()/1000);
  println("Total seconds in dataset:", totalSeconds);
  
  for (TableRow row : tripTable.rows()) {
    int type_id = row.getInt("type_id");
    types.add(type_id);
    
    int tripduration = row.getInt("tripduration");
    int duration = round(map(tripduration, 0, totalSeconds, 0, totalFrames));
    
    try {
      thisStartDate = myDateFormat.parse(row.getString("starttime"));
      thisEndDate = myDateFormat.parse(row.getString("stoptime"));
    } catch (Exception e) {
      println("Unable to parse destination");
    }
    
    int startFrame = floor(map(int(thisStartDate.getTime()/1000), float(int(minDate.getTime()/1000)), float(int(maxDate.getTime()/1000)), 0, totalFrames));
    int endFrame = floor(map(thisEndDate.getTime()/1000, float(int(minDate.getTime()/1000)), float(int(maxDate.getTime()/1000)), 0, totalFrames));
    
    float startLat = row.getFloat("start_lat");
    float startLon = row.getFloat("start_lon");
    float endLat = row.getFloat("end_lat");
    float endLon = row.getFloat("end_lon");
    
    startLocation = new Location(startLat, startLon);
    endLocation = new Location(endLat, endLon);

    trips.add(new Trips(duration, startFrame, endFrame, startLocation, endLocation));
  }
}

void draw() {
  
  if(frameCount < totalFrames) {
    
  map.draw();
  noStroke();
  fill(0,50);
  //fill(0);
  rect(0,0,width,height);
  
  // convert time to epoch
  float epoch_float = map(frameCount, 0, totalFrames, int(minDate.getTime()/1000), int(maxDate.getTime()/1000));
  int epoch = int(epoch_float);
  
  // String date = new java.text.SimpleDateFormat("MM/dd/yyyy hh:mm a").format(new java.util.Date(epoch * 1000L));
  String date = new java.text.SimpleDateFormat("EEEE MMMM d, yyyy").format(new java.util.Date(epoch * 1000L));
  String time = new java.text.SimpleDateFormat("h:mm a").format(new java.util.Date(epoch * 1000L));
  
  // draw trips
  for (int i=0; i < trips.size(); i++) {
    
    Trips trip = trips.get(i);
    
    if (types.get(i) == 1){ // brooklyn bus
      color c = color(65,105,225);
      fill(c, 220);
      trip.plotBusRide();
    } else if (types.get(i) == 2){ // queens bus
      color c = color(0,173,253);
      fill(c, 220);
      trip.plotBusRide();
    } 
  }
  
  // black rectangle underneath timestamp
  //fill(0, 200);
  //rect(32, 60, 440, 200);
  
  f = createFont("AppleSDGothicNeo-Light", 36, true);  // Loading font
  fill(255, 255, 255, 255);
  textFont(f, 44);
  text("Portland Transit Map", 40, 100);
  textFont(f, 26);
  text("TriMet trips on 4-14-2017 ",40, 140);
  //text("Ferry, Citibike and Amtrak Trips", 40, 160);
  
  f = createFont("AppleSDGothicNeo-Light", 36, true);  // Loading font
  fill(255, 255, 255, 255);
  textFont(f, 22);
  //text(date, 40, 200);
  
  f = createFont("AppleSDGothicNeo-Light", 36, true);  // Loading font
  fill(255, 255, 255, 255);
  textFont(f, 28);
  text(time, 40, 225);
  
  f = createFont("AppleSDGothicNeo-Light", 20, true);  // Loading font
  fill(128, 128, 128);
  textFont(f, 22);
  text("@wgeary", 40, 860);

  // Legend
  fill(255, 255, 255);
  //stroke(1);
  fill(65,105,225, 220);
  ellipse(52, 270, 20, 20);
  fill(255,255,255);
  textFont(f, 20);
  text("TriMet", 72, 277);
    
    //saveFrame("frames/######.png");
  } else {
    return;
  }
}

void keyPressed() {
    if (key == '1') {
        map.mapDisplay.setProvider(provider1);
    } else if (key == '2') {
        map.mapDisplay.setProvider(provider2);
    } else if (key == '3') {
        map.mapDisplay.setProvider(provider3);
    } else if (key == '4') {
        map.mapDisplay.setProvider(provider4);
    } else if (key == '5') {
        map.mapDisplay.setProvider(provider5);
    } else if (key == '6') {
        map.mapDisplay.setProvider(provider6);
    } else if (key == '7') {
        map.mapDisplay.setProvider(provider7);
    } else if (key == '8') {
        map.mapDisplay.setProvider(provider8);
    } else if (key == '9') {
        map.mapDisplay.setProvider(provider9);
    } else if (key == '0') {
        map.mapDisplay.setProvider(provider0);
    }
}
