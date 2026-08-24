
## Código para calculo
library(survey)
library(readxl)
library(shiny)
library(shinydashboard)
library(leaflet)
library(ggplot2)
library(tidyr)
library(dplyr)

##rm(list=ls()) ## borrar todos los objetos que tienes guardados en la memoria de R (el panel "Environment)


comparacion <- read_excel("Compara_Censo.xlsx")
##View(comparacion)

##datos_GB <- read_excel("C:/Users/admin/Desktop/CODIGOS_R Y BASES/Compara_Censo.xlsx")

##glimpse(comparacion)



# 1. Preparación de datos y cálculos de Diferencia
datos_completo <- comparacion %>%
  mutate(
    Dif_Area = ((`Area en MZ (ENAPM24-25)` / `Area en MZ (V-Censo)`) - 1) * 100,
    Dif_Prod = ((`Poduccion en QQ (ENAPM24-25)` / `Poduccion en QQ  (V-Censo)`) - 1) * 100,
    Dif_Rend = ((`Rendimiento QQ/MZ (ENAPM24-25)` / `Rendimiento QQ/MZ (V-Censo)`) - 1) * 100
  )

# Coordenadas
coordenadas <- data.frame(
  Departamento = c("Ahuachapán", "Santa Ana", "Sonsonate", "Chalatenango", "La Libertad", 
                   "San Salvador", "Cuscatlán", "La Paz", "Cabañas", "San Vicente", 
                   "Usulután", "San Miguel", "Morazán", "La Unión"),
  lat = c(13.92, 13.98, 13.72, 14.04, 13.67, 13.70, 13.86, 13.52, 13.86, 13.64, 13.34, 13.48, 13.81, 13.33),
  lon = c(-89.84, -89.56, -89.72, -89.17, -89.28, -89.21, -88.93, -88.94, -88.75, -88.78, -88.43, -88.17, -88.10, -87.84)
)
mapa_data <- merge(datos_completo, coordenadas, by = "Departamento")

# 2. Interfaz (Dashboard)
ui <- dashboardPage(
  dashboardHeader(title = "Análisis Agrícola SV"),
  dashboardSidebar(
    selectInput("tipo_var", "Variable:", 
                choices = c("Área" = "Area", "Producción" = "Prod", "Rendimiento" = "Rend")),
    helpText("Semáforo: Verde si ENAPM supera al Censo.")
  ),
  dashboardBody(
    # Fila 1: Tarjetas de Resumen (Value Boxes)
    fluidRow(
      valueBoxOutput("box_censo", width = 4),
      valueBoxOutput("box_enapm", width = 4),
      valueBoxOutput("box_dif", width = 4)
    ),
    # Fila 2: Gráficos y Mapa
    fluidRow(
      box(title = "Comparativo de Barras", status = "primary", solidHeader = TRUE, 
          plotOutput("grafico_dual", height = "500px"), width = 8),
      box(title = "Mapa de Variación", status = "warning", solidHeader = TRUE, 
          leafletOutput("mapa_sv", height = "500px"), width = 4)
    ),
    # Fila 3: Tabla
    fluidRow(
      box(title = "Tabla Detallada con Semáforo de Variación (%)", width = 12, 
          tableOutput("tabla_final"))
    )
  )
)

# 3. Servidor (Reemplaza todo tu bloque server con este)
server <- function(input, output) {
  
  # Lógica para seleccionar columnas dinámicamente
  get_cols <- reactive({
    if(input$tipo_var == "Area") return(list(v="Area en MZ (V-Censo)", e="Area en MZ (ENAPM24-25)", d="Dif_Area"))
    if(input$tipo_var == "Prod") return(list(v="Poduccion en QQ  (V-Censo)", e="Poduccion en QQ (ENAPM24-25)", d="Dif_Prod"))
    return(list(v="Rendimiento QQ/MZ (V-Censo)", e="Rendimiento QQ/MZ (ENAPM24-25)", d="Dif_Rend"))
  })
  
  # TARJETA 1: TOTAL O RENDIMIENTO PONDERADO CENSO
  output$box_censo <- renderValueBox({
    cols <- get_cols()
    if(input$tipo_var == "Rend") {
      val <- sum(mapa_data$`Poduccion en QQ  (V-Censo)`) / sum(mapa_data$`Area en MZ (V-Censo)`)
    } else {
      val <- sum(mapa_data[[cols$v]])
    }
    valueBox(format(round(val, 2), big.mark=","), "Nacional V-Censo", icon = icon("database"), color = "blue")
  })
  
  # TARJETA 2: TOTAL O RENDIMIENTO PONDERADO ENAPM
  output$box_enapm <- renderValueBox({
    cols <- get_cols()
    if(input$tipo_var == "Rend") {
      val <- sum(mapa_data$`Poduccion en QQ (ENAPM24-25)`) / sum(mapa_data$`Area en MZ (ENAPM24-25)`)
    } else {
      val <- sum(mapa_data[[cols$e]])
    }
    valueBox(format(round(val, 2), big.mark=","), "Nacional ENAPM 24-25", icon = icon("chart-line"), color = "green")
  })
  
  # TARJETA 3: VARIACIÓN NACIONAL REAL
  output$box_dif <- renderValueBox({
    if(input$tipo_var == "Rend") {
      r_e <- sum(mapa_data$`Poduccion en QQ (ENAPM24-25)`) / sum(mapa_data$`Area en MZ (ENAPM24-25)`)
      r_c <- sum(mapa_data$`Poduccion en QQ  (V-Censo)`) / sum(mapa_data$`Area en MZ (V-Censo)`)
      dif <- ((r_e / r_c) - 1) * 100
    } else {
      cols <- get_cols()
      dif <- ((sum(mapa_data[[cols$e]]) / sum(mapa_data[[cols$v]])) - 1) * 100
    }
    valueBox(paste0(round(dif, 1), "%"), "Variación Nacional", 
             icon = icon(if(dif > 0) "arrow-up" else "arrow-down"), 
             color = if(dif > 0) "green" else "red")
  })
  # Gráfico Dual
  output$grafico_dual <- renderPlot({
    cols <- get_cols()
    df_long <- mapa_data %>%
      select(Departamento, all_of(c(cols$v, cols$e))) %>%
      pivot_longer(cols = -Departamento, names_to = "Fuente", values_to = "Valor")
    
    ggplot(df_long, aes(x = reorder(Departamento, Valor), y = Valor, fill = Fuente)) +
      geom_bar(stat = "identity", position = "dodge") +
      coord_flip() + theme_minimal() + labs(x="", y="" , fill= NULL) +
      scale_fill_manual(values = c("#3498db", "#2ecc71")) +
      # --- AJUSTE DE TAMAÑO DE LETRA AQUÍ ---
      theme(
        axis.text.y = element_text(size = 12, face = "bold"), # Nombres de departamentos
        axis.text.x = element_text(size = 12, face = "bold"), # NÚMEROS DEL EJE X
        legend.text = element_text(size = 14),
        legend.title = element_text(size = 14, face = "bold")
      )
 
     })
  
  # Mapa con Semáforo
  output$mapa_sv <- renderLeaflet({
    cols <- get_cols()
    # Color según si la diferencia es positiva o negativa
    mapa_data$color_semaforo <- ifelse(mapa_data[[cols$d]] > 0, "green", "red")
    
    leaflet(mapa_data) %>%
      addTiles() %>%
      addCircleMarkers(lat = ~lat, lng = ~lon, 
                       color = ~color_semaforo, 
                       popup = ~paste0(Departamento, ": ", round(mapa_data[[cols$d]], 1), "% de cambio"))
  })
  
  output$tabla_final <- renderTable({
    mapa_data %>% select(Departamento, `Area en MZ (V-Censo)`, `Area en MZ (ENAPM24-25)`, Dif_Area, Dif_Prod, Dif_Rend)
  }, digits = 1)
}

shinyApp(ui, server)
