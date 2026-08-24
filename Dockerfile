FROM rocker/shiny:latest

# Dependencias del sistema
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libgdal-dev \
    libproj-dev \
    libgeos-dev \
    libudunits2-dev

WORKDIR /code

COPY . /code

# Paquetes requeridos para análisis y dashboards
RUN R -e "install.packages(c(\
    'tidyverse', 'readxl', 'writexl', 'haven', 'foreign', \
    'survey', 'srvyr', 'sf', \
    'shinydashboard', 'shinyjs', 'bslib', 'fresh', \
    'plotly', 'DT', 'leaflet', 'leaflet.extras', \
    'scales', 'janitor', 'lubridate'\
    ), repos='https://cloud.r-project.org/')"

# Permite que Shiny escuche en el puerto que Render asigna automáticamente
CMD ["R", "-e", "port <- as.numeric(Sys.getenv('PORT', 3838)); shiny::runApp('/code', host = '0.0.0.0', port = port)"]






