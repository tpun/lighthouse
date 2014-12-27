Products = new Mongo.Collection('products');
Product = {};

Product.processEnterEvent = function (event) {
  console.info(event.visitorUUID, 'entering', event.name);
  Products.upsert({name: event.name},
    {$addToSet: {currentVisitors: event.visitorUUID}});
  BeaconEvents.markProcessed(event);
};

Product.processExitEvent = function (event) {
  var previousEvent = BeaconEvents.findMatchingEnterEvent(event);
  if (!previousEvent) {
    console.warn("[Product.processExitEvent] Can't find matching enter event for _id: ", event._id);
    return;
  }

  var dwell = event.createdAt - previousEvent.createdAt;
  console.info(event.name, " adding ", dwell, " seconds.");
  Products.upsert(
    {name: event.name},
    {$addToSet: {totalVisitors: event.visitorUUID},
     $pull: {currentVisitors: event.visitorUUID},
     $inc: {totalDwell: dwell}}
  );
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
