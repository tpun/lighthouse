BeaconEvents = new Mongo.Collection('beacon_events');

processBeaconEventsFromFirebase = function (json) {
  BeaconEvents.insert(json);
}

BeaconEvents.findMatchingEnterEvent = function (event) {
  return BeaconEvents.findOne(
    { name: event.name,
      type: 'didEnterRegion',
      visitorUUID: event.visitorUUID,
      createdAt: {$lt: event.createdAt}},
    { sort: {createdAt: -1}});
};

BeaconEvents.markProcessed = function (event) {
  BeaconEvents.update(
    { _id: event._id  },
    { $set: {processed: true}});
};

BeaconEvents.findUnprocessedEnterEvents = function () {
  return BeaconEvents.find(
    { type: 'didEnterRegion',
      processed: {$exists: false} }
  );
};

BeaconEvents.findUnprocessedExitEvents = function () {
  return BeaconEvents.find(
    { type: 'didExitRegion',
      processed: {$exists: false} }
  );
};

BeaconEvents.minExitSeconds = 30.0; // iOS only
BeaconEvents.calDwellTimeFromExitEvent = function (exitEvent) {
  var enterEvent = BeaconEvents.findMatchingEnterEvent(exitEvent);
  if (!enterEvent) {
    console.warn("[BeaconEvents.calDwellTime] Can't find matching enter event for _id: ", exitEvent._id);
    return NaN;
  }

  var dwell = exitEvent.createdAt - enterEvent.createdAt;
  if (dwell > BeaconEvents.minExitSeconds) {
    dwell -= BeaconEvents.minExitSeconds;
  }

  return dwell;
}
