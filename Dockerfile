FROM rocker/geospatial:latest

WORKDIR /code

COPY . /code

# Solo instalamos los paquetes livianos del panel de Shiny
RUN R -e "install.packages(c('shinydashboard', 'shinyjs', 'bslib', 'fresh', 'DT', 'plotly', 'srvyr'), repos='https://cloud.r-project.org/')"

# Puerto dinámico adaptado a Render
CMD ["R", "-e", "port <- as.numeric(Sys.getenv('PORT', 3838)); shiny::runApp('/code', host = '0.0.0.0', port = port)"]
