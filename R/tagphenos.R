#' Calculate SNP phenotypic associations
#'
#' tagphenos() reports the frequency of allele types for each SNP and calculates
#' phenotype associations for the different alleles, before returning this
#' information in a $Varfile in a HapObject. This is an internal function that
#' is not intended for external use.
#'
#' @param MGfile SNP marker groups clustered using DBscan.
#' @param bin_vcf Binary VCF for region of interest reformatted by
#' run_haplotyping().
#' @param pheno Input numeric phenotype data for each individual.
#' @param het_phenos When FALSE, phenotype associations for SNPs are calculated
#' from reference and alternate allele individuals only, when TRUE, heterozygous
#' individuals are included assuming additive allele effects.
#'
#' @importFrom rlang ".data"
#'
#' @export
#'
#' @return Returns intermediate of haplotype object.
#'

tagphenos <- function(MGfile, bin_vcf, pheno, het_phenos = FALSE) {

#Split by allele type
bin_vcf_long <- bin_vcf %>%
  tibble::rownames_to_column("ID") %>%
  dplyr::left_join(MGfile, by = "ID") %>%
  tidyr::gather('Ind', 'key', 2:(base::ncol(bin_vcf)))

#Calculate phenotypic association of each allele type for each SNP
preVarfile <- bin_vcf_long %>%
  dplyr::left_join(pheno, by = "Ind") %>%
  dplyr::group_by(.data$ID, .data$MGs, .data$key) %>%
  dplyr::summarize(nInd = dplyr::n(),avPheno=base::mean(.data$Pheno, na.rm = T), .groups = 'keep')

#Rename as ref/het/alt
types <- c(ref = '0', het = '1', alt = '2', miss = '<NA>')

noNA_preVarfile <- preVarfile %>%
  dplyr::select(-'avPheno') %>%
  tidyr::spread(.data$key, .data$nInd) %>%
  dplyr::rename(dplyr::any_of(types))

#Make sure miss is added even if all data is imputed (no missing)
if(!("miss" %in% colnames(noNA_preVarfile))){
  noNA_preVarfile <- dplyr::mutate(noNA_preVarfile, miss = 0)
}

if(!("het" %in% colnames(noNA_preVarfile))){
  noNA_preVarfile <- dplyr::mutate(noNA_preVarfile, het = 0)
}

noNA_preVarfile$MGs[is.na(noNA_preVarfile$MGs)] <- "0"
noNA_preVarfile[is.na(noNA_preVarfile)] <- 0

#Long to wide format and clean for export
Varfile <-  if(het_phenos == FALSE){preVarfile %>% dplyr::select(-'nInd') %>%
    tidyr::spread(.data$key, .data$avPheno) %>%
    dplyr::rename(dplyr::any_of(types)) %>%
    dplyr::mutate(phenodiff = .data$alt - .data$ref) %>%
    dplyr::ungroup() %>%
    dplyr::select('ID', 'phenodiff') %>%
    dplyr::left_join(noNA_preVarfile %>%
                       dplyr::mutate(AltAF = (2*.data$alt+.data$het)/(2*(.data$ref + .data$het + .data$alt))),
                     by = c("ID")) %>%
    dplyr::left_join(MGfile, by = c("ID", "MGs")) %>%
    dplyr::relocate('ID', 'POS', 'cluster', 'MGs', 'ref', 'alt', 'het', 'miss')
}else{preVarfile %>% dplyr::mutate(pheno_total = .data$nInd*.data$avPheno) %>%
    dplyr::select(-c('nInd', 'avPheno'))  %>%
    tidyr::spread(.data$key, .data$pheno_total) %>%
    dplyr::mutate_at(c(3:5), ~replace(., is.na(.), 0)) %>%
    dplyr::left_join(noNA_preVarfile, by = c('ID', 'MGs')) %>%
    dplyr::mutate(phenodiff = (.data$`2` + .5*.data$`1`)/(.5*.data$het+.data$alt) -
                    (.data$`0` + .5*.data$`1`)/(.5*.data$het+.data$ref)) %>%
    dplyr::ungroup() %>%
    dplyr::select('ID', 'phenodiff') %>%
    dplyr::left_join(noNA_preVarfile %>%
                       dplyr::mutate(AltAF = (2*.data$alt+.data$het)/(2*(.data$ref + .data$het + .data$alt))),
                     by = c("ID")) %>%
    dplyr::left_join(MGfile, by = c("ID", "MGs")) %>%
    dplyr::relocate('ID', 'POS', 'cluster', 'MGs', 'ref', 'alt', 'het', 'miss')}

return(Varfile)
}

