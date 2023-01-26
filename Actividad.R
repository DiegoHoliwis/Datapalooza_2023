library(tidyverse)
library(rvest)


pagina <- read_html('https://www.mercadolibre.cl/ofertas?promotion_type=deal_of_the_day&container_id=MLC779365-1&page=1')

Nombres <- pagina %>% 
  html_elements(xpath = '//p[@class = "promotion-item__title"]') %>% 
  html_text2()

precio <- pagina %>% 
  html_elements(xpath = '//span[@class = "promotion-item__price"]') %>% 
  html_text2()
