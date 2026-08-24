FROM rocker/shinyverse:latest

RUN apt-get update && apt-get install -y libssl-dev libcurl4-openssl-dev libxml2-dev

WORKDIR /code

COPY . /code

# Si tu dashboard usa otros paquetes de R (como leaflet, bslib, etc.), agrégalos dentro de c(...)
RUN R -e "install.packages(c('shinydashboard', 'plotly', 'DT', 'readxl'), repos='https://cloud.r-project.org/')"

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/code', host = '0.0.0.0', port = 3838)"]
