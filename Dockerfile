FROM rocker/shiny:latest

RUN apt-get update && apt-get install -y \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev

WORKDIR /code

COPY . /code

# Paquetes requeridos para tu dashboard (puedes agregar más si los necesitas)
RUN R -e "install.packages(c('shinydashboard', 'plotly', 'DT', 'readxl', 'tidyverse'), repos='https://cloud.r-project.org/')"

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/code', host = '0.0.0.0', port = 3838)"]
