## Bibliotecas utilizadas
library(descr)
library(data.table)

## Dicionários de dados (retirados das planilhas da pasta "dicionarios")
dv_domicilios <- read.csv("utilitarios/dv_domicilios.csv", header=FALSE)
dv_pessoas <- read.csv("utilitarios/dv_pessoas.csv", header=FALSE)

## Nomeando colunas dos dicionários de dados
colnames(dv_domicilios) <- c('inicio', 'tamanho', 'variavel')
colnames(dv_pessoas) <- c('inicio', 'tamanho', 'variavel')

## Parâmetro com o final de cada campo
end_domicilios <- dv_domicilios$inicio + dv_domicilios$tamanho - 1
end_pessoas <- dv_pessoas$inicio + dv_pessoas$tamanho - 1

## Converte os microdados para um arquivo .csv
descr::fwf2csv(
  fwffile="dados/DOM2015.txt",
  csvfile="dados/DOM2015.csv",
  names=dv_domicilios$variavel,
  begin=dv_domicilios$inicio,
  end=end_domicilios
)

descr::fwf2csv(
  fwffile="dados/PES2015.txt",
  csvfile="dados/PES2015.csv",
  names=dv_pessoas$variavel,
  begin=dv_pessoas$inicio,
  end=end_pessoas
)

## Lendo dados dos arquivos .csv
dados_domicilios <- data.table::fread(
  input="dados/DOM2015.csv",
  sep="auto",
  sep2="auto",
  integer64="double"
)

dados_pessoas <- data.table::fread(
  input="dados/PES2015.csv",
  sep="auto",
  sep2="auto",
  integer64="double"
)

nrow(dados_domicilios) # Número de domicílios da amostra: 151189
nrow(dados_pessoas) # Número de pessoas da amostra: 356904