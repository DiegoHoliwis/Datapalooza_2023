# Link Rstudio: https://posit.co/download/rstudio-desktop/

# install.packages('tidyverse')
# install.packages('dplyr')
# install.packages('purrr')
# install.packages('rvest')
# install.packages('RSelenium')

# Cambiar de CRAN si este da error, chooseCRANmirror(graphics=FALSE)

library(dplyr)
library(purrr)
library(rvest)

pagina <- read_html("https://www.mercadolibre.cl/ofertas?promotion_type=deal_of_the_day&container_id=MLC779365-2&page=1")

# Extraer Número de páginas
N_paginas <- pagina %>% 
  html_elements(xpath = '//li[@class = "andes-pagination__button"]') %>% #Busqueda exacta de la class
  # html_elements(xpath = '//li[starts-with(@class, "andes-pagination")]') %>% # Buscar class que comience con una palabra
  html_children() %>%
  html_text2() %>% 
  as.numeric() %>% 
  max(na.rm = TRUE) %>% 
  suppressWarnings()

# Extraer los link de mercado libre (ofertas del día)
pagina %>% 
  html_elements(xpath = '//a[@class = "andes-pagination__link"]') %>%
  html_attr('href') %>% 
  unique()

# 'https://www.mercadolibre.cl/ofertas?promotion_type=deal_of_the_day&container_id=MLC779365-2&page=20'

paginas <- 1:20 %>% 
  map_chr(.f = function(x){paste0('https://www.mercadolibre.cl/ofertas?promotion_type=deal_of_the_day&container_id=MLC779365-2&page=',x)})


# scraping página 1

## Nombre

nombre <- pagina %>% 
  html_elements(xpath = '//p[@class = "promotion-item__title"]') %>% 
  html_text2()

## Precio con descuento
# intento 1 fallido
# pagina %>%
#   html_element(xpath = '//span[@class = "andes-money-amount__fraction"]') %>%
#   html_text2()

precio_anterior <- pagina %>% 
  html_elements(xpath = '//div[@class = "andes-money-amount-combo promotion-item__price has-discount"]/s') %>% 
  html_text2()

# precio nuevo
precio_nuevo <- pagina %>% 
  html_elements(xpath = '//div[@class = "andes-money-amount-combo promotion-item__price has-discount"]/div') %>% 
  html_text2()

# envio siguiente día
pagina %>% 
  html_elements(xpath = '//span[@class = "promotion-item__next-day-text"]') %>% 
  html_text2()

pagina %>% 
  html_element(xpath = '//ol[@class = "items_container"]/li[10]//span[@class = "promotion-item__next-day-text"]') %>% 
  html_text2() %>% 
  ifelse(is.na(.),'Sin envio gratis',.)


sprintf('hola %s como estas',1124)
sprintf('//ol[@class = "items_container"]/li[%s]//span[@class = "promotion-item__next-day-text"]',3)


envio_gratis <- 1:length(nombre) %>% 
  map_chr(.f = function(x){
    pagina %>% 
      html_element(xpath = sprintf('//ol[@class = "items_container"]/li[%s]//span[@class = "promotion-item__next-day-text"]',x)) %>% 
      html_text2() %>% 
      ifelse(is.na(.),'Sin envio gratis',.)    
  })
  
#url

url <- pagina %>% 
  html_elements(xpath = '//a[@class = "promotion-item__link-container"]') %>% 
  html_attr('href')

# Consolidado en una función ----

pagina <- read_html("https://www.mercadolibre.cl/ofertas?promotion_type=deal_of_the_day&container_id=MLC779365-2&page=1")

# Extraer Número de páginas
N_paginas <- pagina %>% 
  html_elements(xpath = '//li[@class = "andes-pagination__button"]') %>% 
  html_children() %>%
  html_text2() %>% 
  as.numeric() %>% 
  max(na.rm = TRUE) %>% 
  suppressWarnings()

df <- 1:N_paginas %>% 
  map_dfr(.f = function(k){
    print(paste0('Iniciando scraping de pagina número: ',k))
    pagina <- read_html(sprintf('https://www.mercadolibre.cl/ofertas?promotion_type=deal_of_the_day&container_id=MLC779365-2&page=%s',k))
    
    nombre <- pagina %>% 
      html_elements(xpath = '//p[@class = "promotion-item__title"]') %>% 
      html_text2()
    
    precio_anterior <- pagina %>% 
      html_elements(xpath = '//div[@class = "andes-money-amount-combo promotion-item__price has-discount"]/s') %>% 
      html_text2()

    precio_anterior <- 1:length(nombre) %>% 
      map_chr(.f = function(x){
        pagina %>% 
          html_element(xpath = sprintf('//ol[@class = "items_container"]/li[%s]//div[@class = "andes-money-amount-combo promotion-item__price has-discount"]/s',x)) %>% 
          html_text2() %>% 
          ifelse(is.na(.),'sin precio anterior',.)    
      })

    precio_nuevo <- pagina %>% 
      html_elements(xpath = '//div[@class = "andes-money-amount-combo__main-container"]') %>% 
      html_text2()

    
    envio_gratis <- 1:length(nombre) %>% 
      map_chr(.f = function(x){
        pagina %>% 
          html_element(xpath = sprintf('//ol[@class = "items_container"]/li[%s]//span[@class = "promotion-item__next-day-text"]',x)) %>% 
          html_text2() %>% 
          ifelse(is.na(.),'Sin envio gratis',.)    
      })
    
    url <- pagina %>% 
      html_elements(xpath = '//a[@class = "promotion-item__link-container"]') %>% 
      html_attr('href')
    
    tibble(
      nombre = nombre,
      precio_anterior = precio_anterior,
      precio_nuevo = precio_nuevo,
      envio_gratis = envio_gratis,
      url = url
    )
    
  })

df %>% View()


# install.packages('openxlsx') # instalar libreria
openxlsx::write.xlsx(df, file = 'ofertas mercado libre.xlsx')
