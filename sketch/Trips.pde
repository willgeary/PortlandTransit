class Trips {
 int tripFrames;
 int startFrame;
 int endFrame;
 Location start;
 Location end;
 Location currentLocation;
 ScreenPosition currentPosition;
 
 // class constructor
 Trips(int duration, int start_frame, int end_frame, Location startLocation, Location endLocation) {
       tripFrames = duration;
       startFrame = start_frame;
       endFrame = end_frame;
       start = startLocation;
       end = endLocation;
     }
   
   // function to draw each trip
   void plotTaxiRide(){
     if (frameCount >= startFrame && frameCount < endFrame){
       float percentTravelled = (float(frameCount) - float(startFrame)) / float(tripFrames);
       
       currentLocation = new Location(
         
         lerp(start.x, end.x, percentTravelled),
         lerp(start.y, end.y, percentTravelled));
         
       currentPosition = map.getScreenPosition(currentLocation);

       ellipse(currentPosition.x, currentPosition.y, 3, 3);
       
     }
   }
   
   void plotBusRide(){
     if (frameCount >= startFrame && frameCount < endFrame){
       float percentTravelled = (float(frameCount) - float(startFrame)) / float(tripFrames);
       
       currentLocation = new Location(
         
         lerp(start.x, end.x, percentTravelled),
         lerp(start.y, end.y, percentTravelled));
         
       currentPosition = map.getScreenPosition(currentLocation);

       ellipse(currentPosition.x, currentPosition.y, 10, 10);
      
     }
   }  
}