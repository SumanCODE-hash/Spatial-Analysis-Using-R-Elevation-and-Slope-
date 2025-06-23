# Load necessary libraries
library(tidyverse)
library(raster)
library(sf)
library(ggplot2)
library(RColorBrewer)
library(classInt)
library(viridis)# For natural breaks classification

# Load the DEM file
dem <- raster("output_SRTMGL1.tif")  # Replace with the path to your DEM file

# Calculate the slope from the DEM
slope <- terrain(dem, opt = "slope", unit = "degrees")  # Calculate slope in degrees

# Load the Chittagong district shapefile
ctg <- st_read("Chittagong dist.shp")  # Replace with the path to your shapefile

# Ensure the DEM and shapefile have the same CRS
ctg <- st_transform(ctg, crs = crs(slope))

# Clip the slope raster to the chittagong district boundary
slope_ctg <- mask(crop(slope, ctg), ctg)

# Save the clipped slope map as a TIFF file
writeRaster(slope_ctg, "slope_faridpur.tif", overwrite = TRUE)

# Convert the clipped slope raster to a data frame for ggplot2
slope_df_clipped <- as.data.frame(slope_ctg, xy = TRUE)
colnames(slope_df_clipped) <- c("longitude", "latitude", "slope")

# Classify slope data using natural breaks (Jenks)
num_intervals <- 7  # Number of intervals
breaks <- classIntervals(slope_df_clipped$slope, n = num_intervals, style = "fisher")$brks
interval_labels <- paste(round(breaks[-length(breaks)]), round(breaks[-1]), sep = " - ")

# Assign intervals to the slope data
slope_df_clipped$interval <- cut(slope_df_clipped$slope, breaks = breaks, labels = interval_labels)

# Remove rows with NA values in the interval column
slope_df_clipped <- slope_df_clipped[!is.na(slope_df_clipped$interval), ]

# Define a different color palette (e.g., "RdYlGn" - Red to Yellow to Green)
color_palette <- brewer.pal(num_intervals, "RdYlGn")  # Use "RdYlGn" palette for 7 intervals


# Polting the slope_map
ggplot() +
  geom_raster(data = slope_df_clipped, aes(x = longitude, y = latitude, fill = interval)) +
  geom_sf(data = ctg, fill = NA, color = "black", linewidth = 0.5) +
  scale_fill_manual(values = viridis(num_intervals, option = "C"),
                    name = "Slope (°)",
                    labels = interval_labels) +
  coord_sf(expand = FALSE) +
  annotation_scale(location = "bl", width_hint = 0.5) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering) +
  scale_x_continuous(labels = scales::label_number(suffix = "°E")) +
  scale_y_continuous(labels = scales::label_number(suffix = "°N")) +
  theme_minimal() +
  labs(
    title = "Digital Slope Model (DEM) of Chittagong",
    subtitle = "Slope categorized in 7 levels (in meters)",
    caption = "Data: SRTM | Projection: WGS84"
  ) +
  theme(
    panel.grid.major = element_line(color = "grey", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    axis.text = element_text(size = 8),
    axis.title = element_blank(),
    legend.title = element_text(size = 10, face = "bold"),
    legend.text = element_text(size = 8),
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 10)
  )
