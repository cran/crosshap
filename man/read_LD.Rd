% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{read_LD}
\alias{read_LD}
\title{Read LD correlation matrix to tibble}
\usage{
read_LD(LDin, vcf = NULL)
}
\arguments{
\item{LDin}{Square correlation matrix}

\item{vcf}{VCF object created by read_vcf() that can be used to assign column names}
}
\value{
A tibble.
}
\description{
If your correlation matrix does not have rownames and column names, a VCF
will need to be provided so it can be added with read_LD().
}
