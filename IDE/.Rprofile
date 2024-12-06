options(repos = c(CRAN = "https://cloud.r-project.org"))

options(
  repr.plot.width = 8,
  repr.plot.height = 6,
  repr.plot.res = 300
)

if (interactive()) {
  suppressMessages(require(stats))
  suppressMessages(require(ggplot2))
  suppressMessages(require(tidyverse))
  suppressMessages(require(quantmod))
  suppressMessages(require(xts))
  suppressMessages(require(TTR))
  suppressMessages(require(tidyquant))
}

theme_set(theme_minimal() +
  theme(
    plot.background = element_rect(fill = "white"),
    panel.grid.major = element_line(color = "grey90"),
    panel.grid.minor = element_line(color = "grey95"),
    axis.text = element_text(size = 11),
    axis.title = element_text(size = 12, face = "bold")
  ))

options(
  stringsAsFactors = FALSE,
  digits = 4,
  scipen = 999
)

options(
  getSymbols.warning4.0 = FALSE,
  getSymbols.yahoo.warning = FALSE
)
