library(shiny)
library(tidyverse)
library(shinythemes)
library(leaflet)


seabirds_cleaned_data <- read_csv("data/seabirds_cleaned_data.csv")

birds_9 <- seabirds_cleaned_data %>% 
  group_by(common_name) %>% 
  mutate(common_name = if_else(str_detect(common_name, 
                                          "(?i)shearwater"),"Shearwater", 
                               common_name),
         common_name = if_else(str_detect(common_name, 
                                          "(?i)albatross"), "Albatross",
                               common_name),
         common_name = if_else(str_detect(common_name, 
                                          "(?i)mollymawk"), "Mollymawk",
                               common_name),
         common_name = if_else(str_detect(common_name, 
                                          "(?i)petrel"), "Petrel",
                               common_name),
         common_name = if_else(str_detect(common_name, 
                                          "(?i)prion"), "Prion",
                               common_name),
         common_name = if_else(str_detect(common_name, 
                                          "(?i)skua"), "Skua",
                               common_name),
         common_name = if_else(str_detect(common_name, 
                                          "(?i)penguin"), "Penguin",
                               common_name),
         common_name = if_else(str_detect(common_name, 
                                          "(?i)Red-tailed tropicbird"), 
                               "Red-tailed tropicbird",
                               common_name),
         common_name = if_else(str_detect(common_name, 
                                          "(?i)Brown noddy"), "Brown noddy",
                               common_name)
  ) %>% 
  filter(common_name %in% c("Shearwater", "Albatross", 
                            "Mollymawk", "Petrel", 
                            "Prion", "Skua", 
                            "Penguin", "Brown noddy", 
                            "Red-tailed tropicbird")) %>% 
  arrange(desc(common_name))
  
  
pal <- c("Shearwater" = "#023858", "Albatross" = "#045a8d", 
         "Mollymawk" = "#0570b0", "Petrel" = "#3690c0", 
         "Prion" = "#74a9cf", "Skua" = "#a6bddb", 
         "Penguin" = "#d0d1e6", "Brown noddy" = "#ece7f2", 
         "Red-tailed tropicbird" = "#fff7fb")


bird_count <- birds_9 %>% 
                group_by(common_name) %>% 
                mutate(feeding = if_else(feeding %in% "YES", 1, 0),
                     on_ship = if_else(on_ship %in% "YES", 1, 0),
                     in_hand = if_else(in_hand %in% "YES", 1, 0),
                     fly_by = if_else(fly_by %in% "YES", 1, 0)) %>% 
                summarise(sighting_count = sum(total_sighting, na.rm = TRUE),
                          feeding_count = sum(feeding, na.rm = TRUE),
                          on_ship_count = sum(on_ship, na.rm = TRUE),
                          in_hand_count = sum(in_hand, na.rm = TRUE),
                          fly_by_count = sum(fly_by, na.rm = TRUE))
 


ui <- fluidPage(
  
  
    titlePanel(tags$h1("Seabirds")),
  
    fluidRow(
    
    
               
        sidebarLayout(
            sidebarPanel(
              # check box
                checkboxGroupInput("checkgroup_input", 
                                  label = h3("Select Birds"), 
                                  choices = 
                                    unique(birds_9$common_name),
                                  selected = 
                                    unique(birds_9$common_name)
                ),
              #ACTION BUTTON
                actionButton("update", "Generate Polts and Table"
                )
              
            ),
          
            
            mainPanel(
                tabsetPanel(
                  # First tab  
                    tabPanel("Sighting",
                        plotOutput("sightings")
                    ),
                  # Second tab  
                    tabPanel("Seen Feeding",
                        plotOutput("feeding")
                    ),
                  # Third tab
                    tabPanel("Seen On Ship",
                        plotOutput("on_ship")
                    ),
                  # Forth tab
                    tabPanel("Handled",
                        plotOutput("in_hand")
                    ),
                  # Fifth tab
                    tabPanel("Seen flying",
                        plotOutput("fly_by")
                    ),
                  # Six tab
                    tabPanel("Table",
                             DT::dataTableOutput("table_output")
                    )
                )
            )
           
        ) 
    )
  ,

    fluidRow(

        leafletOutput("map"),
        downloadButton( outputId = "dl")

    )
  
)



server <- function(input, output, session) {
  # ACTION BUTTON
  filtered_birds <- eventReactive(input$update, ignoreNULL = FALSE, {
    
    bird_count %>% 
      filter(common_name %in% input$checkgroup_input)

  })
  
  output$sightings <- renderPlot({
    
      ggplot(filtered_birds()) +
      aes(y = common_name,
          x = log10(sighting_count), fill = common_name) +
      geom_col(col = "black") +
      theme(legend.position = "none") +
      scale_fill_manual(values = pal)
    # log10() as 1 or more birds are less than 10 and don't show on normal graph
    
  })
  
  output$feeding <- renderPlot({
    
    filtered_birds() %>% 
      ggplot() +
      aes(y = common_name, 
          x = log10(feeding_count), fill = common_name) +
      geom_col(col = "black") +
      theme(legend.position = "none") +
      scale_fill_manual(values = pal)
    # log10() as 1 or more birds are less than 10 and don't show on normal graph
  })
  
  output$on_ship <- renderPlot({
    
      ggplot(filtered_birds()) +
      aes(y = common_name, 
          x = on_ship_count, fill = common_name) +
      geom_col(col = "black") +
      theme(legend.position = "none") +
      scale_fill_manual(values = pal)
  })
  
  output$in_hand <- renderPlot({
    
      ggplot(filtered_birds()) +
      aes(y = common_name, 
          x = in_hand_count, fill = common_name) +
      geom_col(col = "black") +
      theme(legend.position = "none") +
      scale_fill_manual(values = pal)
  })
  
  output$fly_by <- renderPlot({
    
      ggplot(filtered_birds()) +
      aes(y = common_name, 
          x = log10(fly_by_count), fill = common_name) +
      geom_col(col = "black") +
      theme(legend.position = "none") +
      scale_fill_manual(values = pal)
  })
  
  output$table_output <- DT::renderDataTable({
    filtered_birds()
    
  })
  
  
  output$map <- renderLeaflet({

    leaflet(data = birds_9) %>%
      addTiles() %>%
      addMarkers(label = bird_count$common_name,
                 clusterOptions = markerClusterOptions())
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)