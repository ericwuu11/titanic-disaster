# Use ARM64 on Apple Silicon; switch to linux/amd64 if you're on Intel
FROM --platform=linux/arm64 rocker/r-base:4.5.1

# System libs required by tidyverse/tidymodels deps (xml2, curl/ssl, ragg stack, etc.)
RUN apt-get update && apt-get install -y \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libicu-dev \
    libharfbuzz-dev libfribidi-dev \
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev libfontconfig1-dev \
    libgfortran5 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install R packages in a cached layer
COPY src/r_model/install_packages.R ./install_packages.R
RUN Rscript install_packages.R

# Copy your model and data preserving the paths your script expects:
# your script reads "src/data/..."
COPY src/r_model/model.R src/r_model/model.R
COPY src/data src/data

# Run your model exactly at its path
CMD ["Rscript", "src/r_model/model.R"]