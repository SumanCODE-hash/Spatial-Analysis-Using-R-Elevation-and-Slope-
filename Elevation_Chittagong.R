# Load necessary libraries
library(tidyverse)
library(raster)
library(sf)
library(ggplot2)
library(RColorBrewer)
library(viridis)
library(ggspatial)# For RColorBrewer color scales

# Load the DEM file
dem <- raster("output_SRTMGL1.tif")  # Replace with the path to your DEM file

# Load the chittagong district shapefile
ctg <- st_read("Chittagong dist.shp")  # Replace with the path to your shapefile

# Ensure the DEM and shapefile have the same CRS
ctg <- st_transform(Feni, crs = crs(dem))

# Clip the DEM to the chittagong district boundary
dem_ctg <- mask(crop(dem, ctg), Feni)

# Save the clipped DEM as a TIFF file
writeRaster(dem_ctg, "clipped_dem_feni.tif", overwrite = TRUE)

# Convert the clipped DEM to a data frame for ggplot2
raster_df_clipped <- as.data.frame(dem_ctg, xy = TRUE)
colnames(raster_df_clipped) <- c("longitude", "latitude", "elevation")

# Define intervals and colors for elevation
num_intervals <- 7  # Number of intervals
interval_breaks <- seq(min(raster_df_clipped$elevation, na.rm = TRUE), 
                       max(raster_df_clipped$elevation, na.rm = TRUE), 
                       length.out = num_intervals + 1)
interval_labels <- paste(round(interval_breaks[-length(interval_breaks)]), 
                         round(interval_breaks[-1]), sep = " - ")

# Assign intervals to the elevation data
raster_df_clipped$interval <- cut(raster_df_clipped$elevation, breaks = interval_breaks, labels = interval_labels)

# Remove rows with NA values in the interval column
raster_df_clipped <- raster_df_clipped[!is.na(raster_df_clipped$interval), ]

# Define a color palette using terrian.color
color_palette <- terrain.colors(num_intervals)


ggplot() +
  geom_raster(data = raster_df_clipped, aes(x = longitude, y = latitude, fill = interval)) +
  geom_sf(data = ctg, fill = NA, color = "black", linewidth = 0.5) +
  scale_fill_manual(values = viridis(num_intervals, option = "C"),
                    name = "Elevation (m)",
                    labels = interval_labels) +
  coord_sf(expand = FALSE) +
  annotation_scale(location = "bl", width_hint = 0.5) +
  annotation_north_arrow(location = "tl", which_north = "true",
                         style = north_arrow_fancy_orienteering) +
  scale_x_continuous(labels = scales::label_number(suffix = "°E")) +
  scale_y_continuous(labels = scales::label_number(suffix = "°N")) +
  theme_minimal() +
  labs(
    title = "Digital Elevation Model (DEM) of Chittagong",
    subtitle = "Elevation categorized in 7 levels (in meters)",
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
