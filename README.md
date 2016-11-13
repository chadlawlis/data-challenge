# Data Challenge

## Part 1

The technical side of this challenge is all about data aggregation and cleanup. We'd like you to combine the contents of five shapefiles and a CartoDB table together into a single dataset. The fields we would like to see in the final dataset are:

1. the "geometry" (of course)
2. a "name"
3. a "type" (campground, parking lot, etc.)
4. a "unit_code" (every National Park Service unit has a four letter alpha code)

The five shapefiles at the root of this repository contain locations for campgrounds, parking lots, restrooms, trailheads, and visitor centers for Arches National Park (unit_code = 'arch').

The CartoDB table (username: `nps` and table name: `points_of_interest`) contains points of interest for the entire National Park Service - including Arches National Park.

## Part 2

The second part of the challenge is documenting the process you walked through to create the dataset. Please try and walk us through your process in a simple and effective way.

## Deliverables

Place all deliverables in the root of this repository, including:

- The final dataset, in GeoJSON format
- A `WALKTHROUGH.md` file documenting your process
- Any other relevant documentation, scripts, or tidbits of code you write while working your way through this challenge
