Products = new Mongo.Collection('products');
Product = {};

Product.processEnterEvent = function (event) {
  console.info(event.visitorUUID, 'entering', event.name);
  Products.upsert({name: event.name},
    {$addToSet: {currentVisitors: event.visitorUUID}});
  BeaconEvents.markProcessed(event);
};

Product.processExitEvent = function (event) {
  var dwell = BeaconEvents.calDwellTimeFromExitEvent(event);
  if (dwell) {
    console.info(event.name, " adding ", dwell, " seconds.");
    Products.upsert(
      {name: event.name},
      {$addToSet: {totalVisitors: event.visitorUUID},
      $pull: {currentVisitors: event.visitorUUID},
      $inc: {totalDwell: dwell}}
    );
  }

  // Always mark event processed.
  BeaconEvents.markProcessed(event);
}

Product.startup = function () {
  BeaconEvents.findUnprocessedEnterEvents().observe({
    "added": Product.processEnterEvent
  });

  BeaconEvents.findUnprocessedExitEvents().observe({
    "added": Product.processExitEvent
  });
};
