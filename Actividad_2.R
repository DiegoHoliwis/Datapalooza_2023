# Actividad número 2 - Selenium
library(tidyverse)
library(rvest)
library(RSelenium)
library(stringr)

# library(tidyverse)
# library(RSelenium)
# library(netstat)
# library(Rcpp)
# library(wdman)

# Configuración inicial (siempre la misma)
system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE) # Se finalizan los procesos Java

driver <- RSelenium::rsDriver(browser = "firefox",
                              chromever = NULL
)
remote_driver <- driver[["client"]]

# Iniciamos el web scraping :D

# Conectamos a la página web
remote_driver$navigate("https://www.santander.cl/cotizador-web/")

MARCA    = 'JEEP'
MODELO   = 'RENEGADE'
AÑO      = '2023'
RUT      = '24312997-4'
NOMBRE   = 'Diego Muñoz'
FechaN   = '10/01/1997'
SEXO     = 'Masculino'
EMAIL    = 'correo_generico@gmail.com'
TELEFONO = runif(1,900000000,999999999) %>% round(0) %>% as.character()

# Pagina 1 -----
# Seleccionar Marca

remote_driver$findElement(using = 'xpath',
                          value = '//select[@id = "marcas"]/option[@value = "78"]')$clickElement()


MARCAS <- remote_driver$findElement(using = 'xpath',
                                    value = '//select[@id = "marcas"]')$selectTag()

ID_MARCA <- tibble(Marca = MARCAS$text,
                   ID_MARCA = MARCAS$value) %>% 
  filter(Marca == MARCA) %>% 
  slice(1) %>% 
  pull(ID_MARCA)

remote_driver$findElement(using = 'xpath',
                          value = paste('//select[@id = "marcas"]/option[@value = ',ID_MARCA,']'))$clickElement()

# Seleccionamos modelo
MODELOS <- remote_driver$findElement(using = 'xpath',
                                     value = '//select[@id = "modelos"]')$selectTag()

ID_MODELO <- tibble(Modelo = MODELOS$text,
                    ID_Modelo = MODELOS$value) %>% 
  filter(Modelo == MODELO) %>% 
  slice(1) %>% 
  pull(ID_Modelo)

remote_driver$findElement(using = 'xpath',
                          value = paste('//select[@id = "modelos"]/option[@value = ',ID_MODELO,']'))$clickElement()

# Seleccionar Año
# remote_driver$findElement(using = 'xpath',
#                           value = '//input[@id = "ano"]')$sendKeysToElement(list('2022'))

remote_driver$findElement(using = 'id',
                          value = 'ano')$sendKeysToElement(list(AÑO))

# Uso
remote_driver$findElement(using = 'xpath',
                          value = '//label[@for = "uso:0"]')$clickElement()

# Dueño
remote_driver$findElement(using = 'xpath',
                          value = '//label[@for = "duenio:0"]')$clickElement()
# Siguiente página
remote_driver$findElement(using = 'id',
                          value = 'siguiente1')$clickElement()

# Página 2 -----

## Rut  ----

remote_driver$findElement(using = 'id',
                          value = 'rutCotizanteDueno')$clickElement()

for(i in RUT %>% str_split("") %>% unlist()){
  remote_driver$findElement(using = 'id',
                            value = 'rutCotizanteDueno')$sendKeysToElement(list(i))
  Sys.sleep(runif(1,1,1.8))
}

# Nombre
for (i in NOMBRE %>% str_split("") %>% unlist()) {
  remote_driver$findElement(using = 'id',
                            value = 'nombre')$sendKeysToElement(list(i))
  Sys.sleep(runif(1,0.1,0.1))
}

# Fecha de nacimiento
for (i in FechaN %>% str_split("") %>% unlist()) {
  remote_driver$findElement(using = 'id',
                            value = 'fechaNacimiento_input')$sendKeysToElement(list(i))
  Sys.sleep(runif(1,0.1,0.3))
}

# Sexo
if(SEXO == "Masculino"){
  remote_driver$findElement(using = 'xpath', value = '//label[@for="sexo:0"]')$clickElement()
}else{
  remote_driver$findElement(using = 'xpath', value = '//label[@for="sexo:1"]')$clickElement()
}

# Email
for (i in EMAIL %>% str_split("") %>% unlist()) {
  remote_driver$findElement(using = 'id',
                            value = 'email')$sendKeysToElement(list(i))
  Sys.sleep(runif(1,0.1,0.3))
}

# Telefono
for (i in TELEFONO %>% str_split("") %>% unlist()) {
  remote_driver$findElement(using = 'id',
                            value = 'telefono')$sendKeysToElement(list(i))
  Sys.sleep(runif(1,0.1,0.3))
}

remote_driver$findElement(using = 'id',
                          value = 'siguiente2_1')$clickElement()

# Página 3 ----
tabla <- remote_driver$findElement(using = "id",
                                   value = "matriz")$getElementAttribute('innerHTML')[[1]] %>% 
  read_html()

precios <- tabla %>% 
  html_table() %>% 
  map_dfc(.f = function(x){
    x %>% 
      select(str_subset(names(.),'Deducible'))
  }) %>% 
  filter(`Deducible 0 UF` != 'Sin Producto')


compañias <- remote_driver$findElement(using = "xpath",
                                       value = '//div[@class = "column-table40"]')$getElementAttribute('innerHTML')[[1]] %>% 
  read_html() %>% 
  html_elements(xpath = '//tr[@class = "filaMatriz"]/td[1]/img') %>% 
  html_attr('alt')

compañias


precios %>% 
  add_column(compañias)
