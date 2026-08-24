FROM rocker/geospatial:latest

WORKDIR /code

COPY . /code

# Instalación de dependencias de R necesarias para la App
RUN R -e "install.packages(c('shinydashboard', 'shinyjs', 'bslib', 'fresh', 'DT', 'plotly', 'srvyr', 'survey'), repos='https://cloud.r-project.org/')"

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/code', host = '0.0.0.0', port = 3838)"]
