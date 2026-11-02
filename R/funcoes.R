# DECISÃO SOBRE OS MESES SEM REGISTRO (Exercício 4 da Lista 03):
# um mês sem registro ("-" no arquivo) é dado ausente, e não produção zero.
# Por isso ele continua NA na tabela arrumada, as somas e médias usam
# na.rm = TRUE, e a contagem de meses com registro usa !is.na(). A decisão
# afeta o total e a média da medida relativa; não afeta a contagem de meses.

# Os doze meses, na ordem do calendário e com os nomes das colunas dos arquivos.
meses <- c(
  "jan", "fev", "mar", "abr", "mai", "jun",
  "jul", "ago", "set", "out", "nov", "dez"
)

# 1. Leitura

# Login do GitHub para o qual os dados foram sorteados, tirado da primeira
# linha do LEIA-ME.txt ("... dados sorteados para o login <login>").
ler_login <- function(arquivo) {
  primeira <- readLines(arquivo, n = 1, warn = FALSE)
  trimws(sub(".*login\\s+", "", primeira))
}

# Cadastro: separado por ";", codificação Latin-1 (acentos dos nomes).
ler_cadastro <- function(arquivo) {
  read_delim(
    arquivo,
    delim = ";",
    locale = locale(encoding = "ISO-8859-1"),
    col_types = cols(
      codigo = col_character(),
      nome = col_character(),
      sistema = col_character(),
      vacas = col_double()
    )
  )
}

# Um arquivo anual: separado por ";", vírgula decimal, "-" para mês sem
# registro, código como texto e os doze meses numéricos.
ler_um_ano <- function(arquivo) {
  read_delim(
    arquivo,
    delim = ";",
    locale = locale(decimal_mark = ",", encoding = "UTF-8"),
    na = "-",
    col_types = cols(
      codigo = col_character(),
      .default = col_double()
    )
  )
}

# Os três arquivos anuais lidos com map() e empilhados, com a origem de cada
# linha e o ano tirado do nome do arquivo.
ler_anuais <- function(arquivos) {
  arquivos |>
    set_names(basename(arquivos)) |>
    map(ler_um_ano) |>
    list_rbind(names_to = "origem") |>
    mutate(ano = as.integer(parse_number(origem)), .after = origem)
}

# 2. Arrumação

# Forma longa (uma linha por unidade, ano e mês), mês como fator na ordem do
# calendário, junção ao cadastro com a cardinalidade conferida e a medida
# relativa (leite por vaca; o leite está em milhares de litros, então a
# medida está em mil litros por vaca).
arrumar_dados <- function(leite_bruto, cadastro) {
  longa <- leite_bruto |>
    pivot_longer(
      cols = all_of(meses),
      names_to = "mes",
      values_to = "leite"
    ) |>
    mutate(mes = factor(mes, levels = meses))

  # Toda unidade medida precisa existir no cadastro.
  stopifnot(all(longa$codigo %in% cadastro$codigo))

  juntada <- longa |>
    left_join(cadastro, by = "codigo", relationship = "many-to-one") |>
    mutate(litros_por_vaca = leite / vacas)

  # A junção não pode mudar o número de linhas.
  stopifnot(nrow(juntada) == nrow(longa))
  juntada
}

# Unidade do cadastro sem medição alguma (junção filtrante).
achar_sem_medicao <- function(cadastro, leite_bruto) {
  anti_join(cadastro, leite_bruto, by = "codigo")
}

# 3. Conferência

# Por ano: unidades com medição, linhas da tabela longa, meses sem registro e
# soma dos valores registrados, para comparar com o LEIA-ME.txt.
gerar_conferencia <- function(dados) {
  dados |>
    group_by(ano) |>
    summarise(
      unidades = n_distinct(codigo),
      linhas = n(),
      meses_sem_registro = sum(is.na(leite)),
      soma = sum(leite, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(ano = factor(ano))
}

# 4. Resumos da Lista 03

# Por unidade, nos três anos: meses com registro, total e média mensal da
# medida relativa, da maior média para a menor.
resumir_unidade <- function(dados) {
  dados |>
    group_by(codigo, nome, sistema) |>
    summarise(
      meses_com_registro = sum(!is.na(leite)),
      total = sum(leite, na.rm = TRUE),
      media_relativa = mean(litros_por_vaca, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(desc(media_relativa))
}

# Por categoria (sistema), nos três anos.
resumir_categoria <- function(dados) {
  dados |>
    group_by(sistema) |>
    summarise(
      unidades = n_distinct(codigo),
      total = sum(leite, na.rm = TRUE),
      media_relativa = mean(litros_por_vaca, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(desc(media_relativa))
}

# Tabela de apresentação: total de cada categoria em cada ano, com uma linha
# por categoria e uma coluna por ano.
resumir_cat_ano <- function(dados) {
  dados |>
    group_by(sistema, ano) |>
    summarise(total = sum(leite, na.rm = TRUE), .groups = "drop") |>
    pivot_wider(names_from = ano, values_from = total)
}

# 5. Resumos do relatório

# Média mensal da medida relativa, por ano e mês (figura de sazonalidade).
resumir_sazonal <- function(dados) {
  dados |>
    group_by(ano, mes) |>
    summarise(
      media_relativa = mean(litros_por_vaca, na.rm = TRUE),
      .groups = "drop"
    ) |>
    mutate(ano = factor(ano))
}

# Média da medida relativa por mês, com os três anos juntos (mês de maior e
# de menor média, citados no texto).
resumir_mes <- function(dados) {
  dados |>
    group_by(mes) |>
    summarise(
      media_relativa = mean(litros_por_vaca, na.rm = TRUE),
      .groups = "drop"
    )
}

# Por ano: unidades, meses com e sem registro, total e média relativa.
resumir_ano <- function(dados) {
  dados |>
    group_by(ano) |>
    summarise(
      unidades = n_distinct(codigo),
      meses_com_registro = sum(!is.na(leite)),
      meses_sem_registro = sum(is.na(leite)),
      total = sum(leite, na.rm = TRUE),
      media_relativa = mean(litros_por_vaca, na.rm = TRUE),
      .groups = "drop"
    ) |>
    arrange(ano) |>
    mutate(ano = factor(ano))
}

# 6. Figuras

grafico_sazonal <- function(resumo_sazonal) {
  ggplot(
    resumo_sazonal,
    aes(x = mes, y = media_relativa, colour = ano, group = ano)
  ) +
    geom_line(linewidth = 0.8) +
    geom_point(size = 2) +
    labs(
      x = "Mês",
      y = "Média mensal (mil litros por vaca)",
      colour = "Ano"
    ) +
    theme_minimal()
}

grafico_categorias <- function(dados) {
  dados |>
    filter(!is.na(litros_por_vaca)) |>
    ggplot(aes(x = sistema, y = litros_por_vaca)) +
    geom_boxplot(fill = "grey90") +
    labs(x = "Sistema", y = "Mil litros por vaca no mês") +
    theme_minimal()
}

# 7. Modelo (opcional)

# Os valores são produto de efeitos; no logaritmo, eles se somam.
ajustar_modelo <- function(dados) {
  dados_modelo <- filter(dados, !is.na(litros_por_vaca), litros_por_vaca > 0)
  lm(log(litros_por_vaca) ~ ano + mes + sistema, data = dados_modelo)
}

# Variação anual estimada, em proporção, com o intervalo de confiança de 95%.
variacao_anual <- function(modelo) {
  estimativa <- coef(modelo)[["ano"]]
  intervalo <- confint(modelo)["ano", ]
  tibble(
    variacao = exp(estimativa) - 1,
    inferior = exp(intervalo[[1]]) - 1,
    superior = exp(intervalo[[2]]) - 1
  )
}
