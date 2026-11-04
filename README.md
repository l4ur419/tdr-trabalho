# tdr-trabalho

Trabalho intermediário de Tecnologia de Dados (UFPR): a análise da Lista 03,
sobre o leite entregue pelas fazendas de uma cooperativa em 2023, 2024 e 2025,
transformada em um projeto reprodutível com `targets`, Quarto, `renv` e
GitHub Actions. Os dados são simulados e foram sorteados para o meu login do
GitHub.

## Como reproduzir

Antes, é preciso ter instalados o R, o [Quarto](https://quarto.org) e o Git.
Depois de clonar o repositório, abra o R na raiz do projeto e rode:

```r
renv::restore()
targets::tar_make()
```

O primeiro comando instala as versões dos pacotes registradas no `renv.lock`;
o segundo executa o pipeline e gera o `relatorio.html`.

## O que há em cada arquivo

| Arquivo | Conteúdo |
|---|---|
| `dados/` | Os cinco arquivos do zip da Lista 03, sem alteração |
| `R/funcoes.R` | Uma função por etapa: leitura, arrumação, conferência, resumos, figuras e modelo |
| `_targets.R` | A definição do pipeline |
| `relatorio.qmd` | O relatório, que só lê alvos do pipeline |
| `_dependencies.R` | Pacotes que o `renv` não encontraria sozinho (não é executado) |
| `renv.lock`, `.Rprofile`, `renv/` | O ambiente de pacotes do projeto |
| `.github/workflows/relatorio.yaml` | A integração contínua, que executa o pipeline a cada envio |
| `.lintr` | O estilo do projeto, verificado com `lintr::lint_dir()` |

## Decisão sobre os meses sem registro

Um mês sem registro é tratado como dado ausente, e não como produção zero.
Somas e médias ignoram esses meses; a contagem de meses com registro não é
afetada.

## Uso de LLMs

Usei o Claude (Anthropic) nas seguintes partes do trabalho:
- Auxílio ao reescrever as funções de `R/funcoes.R`;
- Montar o `_targets.R` e o `relatorio.qmd`;
- Escrever o `.github/workflows/relatorio.yaml` e o rascunho deste README;
- Diagnosticar erros durante o trabalho (caminho do `source()`, `.lintr`
  vazio, ativação do `renv`).

Para conferência de resultados:
- Rodando `targets::tar_make()` em uma sessão nova do R e comparando a
  tabela de conferência com o `LEIA-ME.txt` (linhas, meses sem registro e
  somas de cada ano iguais);
- Rodando `lintr::lint_dir()` sem problemas;
- Restaurando o projeto em um clone limpo com `renv::restore()` e
  executando o pipeline nele.
