FROM rocker/shiny:latest

# Instalación de librerías del sistema Linux (requeridas para leaflet y sf)
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

# Instalación de paquetes de R en bloques para asegurar su instalación
RUN R -e "install.packages(c('tidyverse', 'readxl', 'writexl', 'haven', 'foreign', 'janitor', 'lubridate'), repos='https://cloud.r-project.org/')"
RUN R -e "install.packages(c('shinydashboard', 'shinyjs', 'bslib', 'fresh', 'DT', 'plotly'), repos='https://cloud.r-project.org/')"
RUN R -e "install.packages(c('survey', 'srvyr', 'sf', 'leaflet', 'leaflet.extras'), repos='https://cloud.r-project.org/')"

# Configuración del puerto dinámico para Render
CMD ["R", "-e", "port <- as.numeric(Sys.getenv('PORT', 3838)); shiny::runApp('/code', host = '0.0.0.0', port = port)"]





