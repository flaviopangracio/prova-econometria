## Bibliotecas utilizadas
library(descr)
library(data.table)
library(dplyr)

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

df_domicilios <- dplyr::as_tibble(dados_domicilios)
df_pessoas <- dplyr::as_tibble(dados_pessoas)


## Selecionando e renomeando as variáveis utilizadas
cl_pessoas = df_pessoas |>
  dplyr::select(
    ano="V0101",
    uf="UF",
    controle="V0102",
    serie="V0103",
    ordem="V0301",
    sexo="V0302",
    idade="V8005",
    condicao_na_familia="V0402",
    cor="V0404",
    anos_de_estudo="V4803",
    rendimento_mensal_familiar_per_capita="V4722"
  )

cl_domicilios = df_domicilios |>
  dplyr::select(
    ano="V0101",
    uf="UF",
    controle="V0102",
    serie="V0103",
    total_de_moradores="V0105",
    condicao_de_ocupacao_do_domicilio="V0207",
    strat="V4617",
    psu="V4618"
  )

# Unindo os dados de pessoas e domicílios (amostragem complexa)
joined_df <- dplyr::inner_join(
  cl_pessoas,
  cl_domicilios,
  by=c("ano", "uf", "controle", "serie")
)

## Removendo indivíduos sem rendimento mensal familiar per capita.
joined_df <- joined_df |> filter(!is.na(rendimento_mensal_familiar_per_capita))

## Criando variável binária para pessoa de referência na família
pessoa_de_referencia_na_familia <- ifelse(joined_df$condicao_na_familia == 1, 1, 0)

joined_df$pessoa_de_referencia_na_familia <- pessoa_de_referencia_na_familia

## Sexo como variável binária (Masculino = 1, Feminino = 0)
joined_df$sexo <- ifelse(joined_df$sexo == 2, 1, 0)

## Criando dummies para cor/raça

joined_df$cor_branca <- ifelse(joined_df$cor == 2, 1, 0)
joined_df$cor_preta <- ifelse(joined_df$cor == 4, 1, 0)
joined_df$cor_amarela <- ifelse(joined_df$cor == 6, 1, 0)
joined_df$cor_parda <- ifelse(joined_df$cor == 8, 1, 0)
joined_df$cor_indigena <- ifelse(joined_df$cor == 0, 1, 0)
joined_df$cor_sem_declaracao <- ifelse(joined_df$cor == 9, 1, 0)



## Criando dummy de casa própria (Imóvel pago ou em pagamento: 1. Caso contrário: 0)
joined_df$casa_propria <- ifelse(joined_df$condicao_de_ocupacao_do_domicilio == 1 | joined_df$condicao_de_ocupacao_do_domicilio == 2, 1, 0)


## Amostra para indivíduos com renda familiar per capita entre R$500,00 e R$20.000,00
amostra <- joined_df |>
  filter(rendimento_mensal_familiar_per_capita >= 500 & rendimento_mensal_familiar_per_capita <= 20000)

## Estimando um Logit para os dados da amostra
reglogit <- glm("casa_propria ~ rendimento_mensal_familiar_per_capita", data=amostra,x=TRUE, y=TRUE,family = binomial(link="logit"))

summary(reglogit)

## Probabilidade de um indivíduo possuir uma casa, com renda mensal per capita de 1000
mil <- 1/(1 + exp(-(reglogit$coefficients[1] + reglogit$coefficients[2]*1000))) # 0.7428796

## Probabilidade de um indivíduo possuir uma casa, com renda mensal per capita de 3000
tresmil <- 1/(1 + exp(-(reglogit$coefficients[1] + reglogit$coefficients[2]*3000))) # 0.7657695

## Probabilidade de um indivíduo possuir uma casa, com renda mensal per capita de 5000
cincomil <- 1/(1 + exp(-(reglogit$coefficients[1] + reglogit$coefficients[2]*5000))) # 0.7872053

## Intervalo de confiança para os parâmtros
intervalo <- cbind(OR=coef(reglogit), confint(reglogit))

##                                                OR        2.5 %       97.5 %
##(Intercept)                           9.991964e-01 9.869193e-01 1.011473e+00
##rendimento_mensal_familiar_per_capita 6.179301e-05 5.847868e-05 6.512564e-05

## Intervalo de confiança 1000 reais, alpha = 0.05:
1/(1 + exp(-(intervalo[3] + intervalo[4]*1000))) # 0.7398902
1/(1 + exp(-(intervalo[5] + intervalo[6]*1000))) # 0.7458497
## 0.7398902 < 0.7428796 < 0.7458497

## Intervalo de confiança 3000 reais, alpha = 0.05:ano
1/(1 + exp(-(intervalo[3] + intervalo[4]*3000))) # 0.7617604
1/(1 + exp(-(intervalo[5] + intervalo[6]*3000))) # 0.7697411
## 0.7617604 < 0.7657695 < 0.7697411

## Intervalo de confiança 5000 reais, alpha = 0.05:ano
1/(1 + exp(-(intervalo[3] + intervalo[4]*5000))) # 0.7823328
1/(1 + exp(-(intervalo[5] + intervalo[6]*5000))) # 0.7920128
## 0.7823328 < 0.7872053 < 0.7920128

#### Como não há pontos em comum nos intervalos de confiança com alpha de 5%,
#### podemos dizer que os resultados são estatisticamente diferentes.


## Efeitos marginais
logitescalar <-(mean(dlogis(predict(reglogit,type='link'))))
logitescalar * coef(reglogit)

# Intercept: 1.791026e-01
# rendimento_mensal_familiar_per_capita: 1.107619e-05

#### Os efeitos marginais nos dizem que a variação de 1 unidade na renda per capita mensal,
#### aumenta em 1.107619e-05 a probabilidade de um indivíduo possuir uma casa.