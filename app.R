# ============================================================
# app.R - Dashboard ODS 2.4.1
# ============================================================

library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)

# Cargar los datos guardados
load("datos_finales.RData")

# Preparar datos para el gráfico
nombres_sub <- c(
  "1. Valor producción/ha",
  "2. Ingresos agrícolas netos",
  "3. Mitigación de riesgos",
  "4. Degradación del suelo",
  "5. Disponibilidad de agua",
  "6. Gestión de fertilizantes",
  "7. Gestión de plaguicidas",
  "8. Prácticas de biodiversidad",
  "9. Salarios en agricultura",
  "10. Inseguridad alimentaria (FIES)",
  "11. Seguridad de tenencia"
)

# Función para extraer valores
extraer_valor <- function(df, n, categoria) {
  if(is.null(df) || nrow(df) == 0) return(0)
  col_name <- paste0("porc_super", n)
  if(!col_name %in% names(df)) return(0)
  valor <- df[[col_name]][df$subindicador == categoria]
  if(length(valor) == 0) return(0)
  return(round(valor, 1))
}

# Crear dataframe con los valores
datos_dashboard <- data.frame(Subindicador = nombres_sub)

for(i in 1:11) {
  df_name <- paste0("final_", i)
  if(exists(df_name)) {
    df <- get(df_name)
    datos_dashboard$Verde[i] <- extraer_valor(df, i, "1. Verde (deseable)")
    datos_dashboard$Amarillo[i] <- extraer_valor(df, i, "2. Amarillo (aceptable)")
    datos_dashboard$Rojo[i] <- extraer_valor(df, i, "3. Rojo (insostenible)")
  } else {
    datos_dashboard$Verde[i] <- 0
    datos_dashboard$Amarillo[i] <- 0
    datos_dashboard$Rojo[i] <- 0
  }
}

datos_dashboard$Subindicador <- factor(datos_dashboard$Subindicador, 
                                       levels = datos_dashboard$Subindicador)

# Formato largo para gráficos
datos_largos <- datos_dashboard %>%
  pivot_longer(cols = c("Verde", "Amarillo", "Rojo"),
               names_to = "Categoria",
               values_to = "Porcentaje") %>%
  filter(Porcentaje > 0)

# UI
ui <- fluidPage(
  titlePanel("Indicador ODS 2.4.1 - El Salvador"),
  sidebarLayout(
    sidebarPanel(
      h3("Controles"),
      selectInput("subindicador", 
                  "Seleccionar subindicador:",
                  choices = c("Todos", as.character(datos_dashboard$Subindicador)),
                  selected = "Todos"),
      hr(),
      p("Datos de la encuesta ENAPM 2025"),
      p(paste0("Total de subindicadores: ", nrow(datos_dashboard)))
    ),
    mainPanel(
      plotOutput("grafico", height = "500px")
    )
  )
)

# Server
server <- function(input, output) {
  
  datos_filtrados <- reactive({
    if(input$subindicador == "Todos") {
      return(datos_largos)
    } else {
      return(datos_largos %>% filter(Subindicador == input$subindicador))
    }
  })
  
  output$grafico <- renderPlot({
    datos <- datos_filtrados()
    
    datos$Categoria <- factor(datos$Categoria, 
                              levels = c("Verde", "Amarillo", "Rojo"))
    
    ggplot(datos, aes(x = Subindicador, y = Porcentaje, fill = Categoria)) +
      # Ancho dinámico: si hay 3 filas (un solo subindicador), ancho 0.3; si no, 0.7
      geom_bar(stat = "identity", position = "stack", 
               width = ifelse(nrow(datos) == 3, 0.15, 0.7), 
               color = "black") +
      geom_text(aes(label = ifelse(Porcentaje > 3, paste0(round(Porcentaje, 1), "%"), "")),
                position = position_stack(vjust = 0.5), size = 4, fontface = "bold", color = "white") +
      scale_fill_manual(
        values = c("Verde" = "#2E7D32", "Amarillo" = "#F9A825", "Rojo" = "#C62828"),
        labels = c("Verde (Deseable)", "Amarillo (Aceptable)", "Rojo (Insostenible)")
      ) +
      scale_y_continuous(limits = c(0, 101), breaks = seq(0, 100, 20),
                         labels = function(x) paste0(x, "%")) +
      labs(
        title = "Proporción de superficie agrícola por categoría de sostenibilidad",
        x = "", y = "Porcentaje (%)", fill = "Sostenibilidad"
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1, size = 11, face = "bold"),
        legend.position = "bottom"
      )
  })
}
# Ejecutar la aplicación
shinyApp(ui = ui, server = server)






