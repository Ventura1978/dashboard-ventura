FROM rocker/shiny:latest

# Dependencias del sistema operativo Linux requeridas por R
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

# Instalación masiva de paquetes para dashboards, encuestas y datos
RUN R -e "install.packages(c(\
    'tidyverse', 'readxl', 'writexl', 'haven', 'foreign', \
    'survey', 'srvyr', 'spatstat', 'sf', \
    'shinydashboard', 'shinyjs', 'bslib', 'fresh', \
    'plotly', 'DT', 'leaflet', 'leaflet.extras', 'echarts4r', \
    'scales', 'janitor', 'lubridate', 'knitr', 'rmarkdown' \
    ), repos='https://cloud.r-project.org/')"

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/code', host = '0.0.0.0', port = 3838)"]
