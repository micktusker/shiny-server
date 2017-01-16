library(shiny)
library(DBI)
createSqliteDb <- function(sqlite.db.path) {
  sqlite.conn <- dbConnect(RSQLite::SQLite(), sqlite.db.path)
  return(sqlite.conn)
}
sqlite.conn <- createSqliteDb('../tcga/gdac_tcga_data.db')
shinyServer(function(input, output, session) {
  output$plotter <- renderPlot({
    conn <- sqlite.conn
    query1 <- paste0("SELECT expression_values FROM tcga_mrna_normalized_matrices mat JOIN tcga_file_cancer_code_lookup lu ON mat.file_code = lu.file_code WHERE mat.gene_name = '", input$GeneA, "' AND lu.tcga_cancer_code = '", input$TCGACode, "'")
    gene.a <- dbGetQuery(conn, query1)
    gene.a.df <- as.data.frame(gene.a)
    values.gene.a <- as.numeric((strsplit(gene.a.df$expression_values, '|', fixed = TRUE))[[1]])
    query2 <- paste0("SELECT expression_values FROM tcga_mrna_normalized_matrices mat JOIN tcga_file_cancer_code_lookup lu ON mat.file_code = lu.file_code WHERE mat.gene_name = '", input$GeneB, "' AND lu.tcga_cancer_code = '", input$TCGACode, "'")
    gene.b <- dbGetQuery(conn, query2)
    gene.b.df <- as.data.frame(gene.b)
    values.gene.b <- as.numeric((strsplit(gene.b.df$expression_values, '|', fixed = TRUE))[[1]])
    table.out <- as.data.frame(cbind(values.gene.a, values.gene.b))
    names(table.out) <- c("GeneA", "GeneB")
    table.out <- table.out[order(table.out$GeneA),]
    plot(table.out$GeneA, table.out$GeneB)
  })
  output$summary<- renderTable({
    conn <- sqlite.conn
    query1 <- paste0("SELECT expression_values FROM tcga_mrna_normalized_matrices mat JOIN tcga_file_cancer_code_lookup lu ON mat.file_code = lu.file_code WHERE mat.gene_name = '", input$GeneA, "' AND lu.tcga_cancer_code = '", input$TCGACode, "'")
    gene.a <- dbGetQuery(conn, query1)
    gene.a.df <- as.data.frame(gene.a)
    values.gene.a <- as.numeric((strsplit(gene.a.df$expression_values, '|', fixed = TRUE))[[1]])
    query2 <- paste0("SELECT expression_values FROM tcga_mrna_normalized_matrices mat JOIN tcga_file_cancer_code_lookup lu ON mat.file_code = lu.file_code WHERE mat.gene_name = '", input$GeneB, "' AND lu.tcga_cancer_code = '", input$TCGACode, "'")
    gene.b <- dbGetQuery(conn, query2)
    gene.b.df <- as.data.frame(gene.b)
    values.gene.b <- as.numeric((strsplit(gene.b.df$expression_values, '|', fixed = TRUE))[[1]])
    stats <- cor.test(values.gene.a, values.gene.b)
    summary.stats <- data.frame()
    summary.row <- c(stats$estimate, stats$p.value, stats$conf.int)
    summary.stats <- rbind(summary.stats, summary.row)
    names(summary.stats) <- c("corr.coeff", "pvalue", "conf.int.lower", "conf.int.upper")
    summary.stats
  })
  output$tbl<- renderTable({
    conn <- sqlite.conn
    query1 <- paste0("SELECT expression_values FROM tcga_mrna_normalized_matrices mat JOIN tcga_file_cancer_code_lookup lu ON mat.file_code = lu.file_code WHERE mat.gene_name = '", input$GeneA, "' AND lu.tcga_cancer_code = '", input$TCGACode, "'")
    gene.a <- dbGetQuery(conn, query1)
    gene.a.df <- as.data.frame(gene.a)
    values.gene.a <- as.numeric((strsplit(gene.a.df$expression_values, '|', fixed = TRUE))[[1]])
    query2 <- paste0("SELECT expression_values FROM tcga_mrna_normalized_matrices mat JOIN tcga_file_cancer_code_lookup lu ON mat.file_code = lu.file_code WHERE mat.gene_name = '", input$GeneB, "' AND lu.tcga_cancer_code = '", input$TCGACode, "'")
    gene.b <- dbGetQuery(conn, query2)
    gene.b.df <- as.data.frame(gene.b)
    values.gene.b <- as.numeric((strsplit(gene.b.df$expression_values, '|', fixed = TRUE))[[1]])
    table.out <- as.data.frame(cbind(values.gene.a, values.gene.b))
    names(table.out) <- c("GeneA", "GeneB")
    table.out <- table.out[order(table.out$GeneA),]
  })
})