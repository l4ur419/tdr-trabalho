library(targets)
library(tarchetypes)

# Carrega todas as funções de R/ (caminho relativo à raiz do projeto).
tar_source()

tar_option_set(packages = c("readr", "dplyr", "tidyr", "purrr", "ggplot2"))

list(
  # 1. Arquivos de dados como alvos de arquivo
  tar_target(arq_cadastro, "dados/cadastro.csv", format = "file"),
  tar_target(arq_leite_23, "dados/leite_2023.csv", format = "file"),
  tar_target(arq_leite_24, "dados/leite_2024.csv", format = "file"),
  tar_target(arq_leite_25, "dados/leite_2025.csv", format = "file"),
  tar_target(arq_leia_me, "dados/LEIA-ME.txt", format = "file"),

  # 2. Leitura
  tar_target(login, ler_login(arq_leia_me)),
  tar_target(cadastro, ler_cadastro(arq_cadastro)),
  tar_target(
    leite_bruto,
    ler_anuais(c(arq_leite_23, arq_leite_24, arq_leite_25))
  ),

  # 3. Tabela arrumada e unidade sem medição
  tar_target(dados_limpos, arrumar_dados(leite_bruto, cadastro)),
  tar_target(sem_medicao, achar_sem_medicao(cadastro, leite_bruto)),

  # 4. Conferência contra o LEIA-ME.txt
  tar_target(conferencia, gerar_conferencia(dados_limpos)),

  # 5. Resumos da Lista 03 e do relatório
  tar_target(resumo_unidade, resumir_unidade(dados_limpos)),
  tar_target(resumo_categoria, resumir_categoria(dados_limpos)),
  tar_target(resumo_cat_ano, resumir_cat_ano(dados_limpos)),
  tar_target(resumo_sazonal, resumir_sazonal(dados_limpos)),
  tar_target(resumo_mes, resumir_mes(dados_limpos)),
  tar_target(resumo_anual, resumir_ano(dados_limpos)),

  # Figuras
  tar_target(fig_sazonal, grafico_sazonal(resumo_sazonal)),
  tar_target(fig_categorias, grafico_categorias(dados_limpos)),

  # Modelo (opcional)
  tar_target(modelo, ajustar_modelo(dados_limpos)),
  tar_target(efeito_ano, variacao_anual(modelo)),

  # 6. Relatório
  tar_quarto(relatorio, "relatorio.qmd")
)
